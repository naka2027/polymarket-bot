#!/usr/bin/env bash
set -euo pipefail
umask 077

# One-time legacy flat-layout migration. This script is intentionally separate
# from install-cloud.sh; normal installation and future updates never scan the
# host or infer an installation directory.
BRAND_ID="${POLYNEXUS_UPDATE_BRAND_ID:-polymarket}"
APP_NAME="${POLYNEXUS_UPDATE_APP_NAME:-Polymarket}"
RELEASE_REPO="${POLYNEXUS_UPDATE_RELEASE_REPO:-naka2027/polymarket-bot}"
CLOUD_EXECUTABLE="${POLYNEXUS_UPDATE_CLOUD_EXECUTABLE:-PolymarketCloud}"
MIGRATION_ENV_FILE="${POLYNEXUS_ENV_FILE:-/etc/${BRAND_ID}/cloud.env}"

die() { printf '%s\n' "$*" >&2; exit 1; }

SOURCE_DIR=""
INSTALLER_SOURCE=""
AUTO_DISCOVER=0
SUPERVISOR_MODE="baota"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-dir) SOURCE_DIR="$2"; shift 2 ;;
    --installer) INSTALLER_SOURCE="$2"; shift 2 ;;
    --auto) AUTO_DISCOVER=1; shift ;;
    --supervisor) SUPERVISOR_MODE="$2"; shift 2 ;;
    *) die "Usage: migrate-cloud.sh (--source-dir PATH | --auto) [--installer PATH] [--supervisor MODE]" ;;
  esac
done

[[ "$EUID" -eq 0 ]] || die "Run this migration once as root, for example: sudo bash migrate-cloud.sh --auto"
[[ -n "$SOURCE_DIR" || "$AUTO_DISCOVER" == "1" ]] || die "Specify --source-dir or --auto."
command -v sha256sum >/dev/null 2>&1 || die "sha256sum is required for legacy installation verification."
command -v curl >/dev/null 2>&1 || die "curl is required for legacy migration."

normalize_dir() {
  local value="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath -m "$value"
  else
    readlink -m "$value"
  fi
}

is_legacy_candidate() {
  local candidate="$1" expected actual manifest
  [[ -d "$candidate" ]] || return 1
  [[ -x "$candidate/$CLOUD_EXECUTABLE" ]] || return 1
  manifest="$candidate/${CLOUD_EXECUTABLE}.integrity.json"
  [[ -f "$manifest" ]] || return 1
  expected="$(sed -n 's/.*"sha256"[[:space:]]*:[[:space:]]*"\([0-9a-fA-F]\{64\}\)".*/\1/p' "$manifest" | head -n 1 | tr 'A-F' 'a-f')"
  [[ "$expected" =~ ^[0-9a-f]{64}$ ]] || return 1
  actual="$(sha256sum "$candidate/$CLOUD_EXECUTABLE" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || return 1
  [[ ! -f "$candidate/.cloud-install-root" ]] || return 1
  [[ "$candidate" != */releases/* ]] || return 1
  [[ -f "$candidate/config.toml" ]] || return 1
  [[ -f "$candidate/bt-cloud-guard.sh" ]] || return 1
  bash -n "$candidate/bt-cloud-guard.sh" >/dev/null 2>&1 || return 1
}

read_persisted_master_key() {
  [[ -f "$MIGRATION_ENV_FILE" ]] || return 0
  (
    unset POLYNEXUS_MASTER_KEY
    set -a
    # shellcheck disable=SC1090
    source "$MIGRATION_ENV_FILE"
    set +a
    printf '%s' "${POLYNEXUS_MASTER_KEY:-}"
  ) 2>/dev/null || true
}

persist_migration_master_key() {
  local key_value="$1"
  local env_dir
  [[ -n "$key_value" ]] || return 1
  env_dir="$(dirname "$MIGRATION_ENV_FILE")"
  umask 077
  mkdir -p "$env_dir"
  if [[ -f "$MIGRATION_ENV_FILE" ]]; then
    printf '\nPOLYNEXUS_MASTER_KEY=%q\n' "$key_value" >> "$MIGRATION_ENV_FILE"
  else
    printf 'POLYNEXUS_MASTER_KEY=%q\n' "$key_value" > "$MIGRATION_ENV_FILE"
  fi
  chmod 600 "$MIGRATION_ENV_FILE" 2>/dev/null || true
}

read_process_environment_value() {
  local pid="$1" variable_name="$2"
  [[ "$pid" =~ ^[0-9]+$ && -r "/proc/$pid/environ" ]] || return 0
  tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null \
    | awk -v prefix="${variable_name}=" \
        'index($0, prefix) == 1 { value = substr($0, length(prefix) + 1) } END { printf "%s", value }'
}

read_process_argument() {
  local pid="$1" wanted="$2" argument="" return_next=0
  [[ "$pid" =~ ^[0-9]+$ && -r "/proc/$pid/cmdline" ]] || return 0
  while IFS= read -r -d '' argument; do
    if [[ "$return_next" == "1" ]]; then
      printf '%s' "$argument"
      return 0
    fi
    case "$argument" in
      "$wanted") return_next=1 ;;
      "$wanted="*) printf '%s' "${argument#*=}"; return 0 ;;
    esac
  done < "/proc/$pid/cmdline"
}

read_process_master_key() {
  read_process_environment_value "$1" POLYNEXUS_MASTER_KEY
}

read_persisted_runtime_value() {
  local variable_name="$1"
  [[ -f "$MIGRATION_ENV_FILE" ]] || return 0
  (
    unset XDG_STATE_HOME
    set -a
    # shellcheck disable=SC1090
    source "$MIGRATION_ENV_FILE"
    set +a
    case "$variable_name" in
      XDG_STATE_HOME) printf '%s' "${XDG_STATE_HOME:-}" ;;
      *) return 1 ;;
    esac
  ) 2>/dev/null || true
}

read_process_uid() {
  local pid="$1"
  [[ "$pid" =~ ^[0-9]+$ && -r "/proc/$pid/status" ]] || return 0
  awk '/^Uid:/ { printf "%s", $2; exit }' "/proc/$pid/status" 2>/dev/null || true
}

verify_secret_storage_continuity() {
  local config_path="$1" running_key="${2:-}" current_key="${POLYNEXUS_MASTER_KEY:-}"
  local persisted_key="" effective_key=""
  [[ -f "$config_path" ]] || return 0
  if grep -Fq 'enc:dpapi:' "$config_path"; then
    die "The legacy config contains Windows DPAPI secrets and cannot be migrated to Linux. Re-enter the live credentials on Linux instead."
  fi
  grep -Fq 'enc:aesgcm:v1:' "$config_path" || return 0
  persisted_key="$(read_persisted_master_key)"
  if [[ -n "$running_key" && -n "$current_key" && "$running_key" != "$current_key" ]]; then
    die "The supplied POLYNEXUS_MASTER_KEY differs from the key used by the running legacy process."
  fi
  if [[ -n "$current_key" && -n "$persisted_key" && "$current_key" != "$persisted_key" ]]; then
    if [[ -z "$running_key" ]]; then
      die "POLYNEXUS_MASTER_KEY differs from the persisted key in $MIGRATION_ENV_FILE. Refusing to migrate encrypted credentials."
    fi
  fi
  effective_key="${running_key:-${current_key:-$persisted_key}}"
  if [[ -z "$effective_key" ]]; then
    die "The legacy config contains encrypted credentials. Export the exact original POLYNEXUS_MASTER_KEY or restore it in $MIGRATION_ENV_FILE before migration."
  fi
  if [[ "$effective_key" != "$persisted_key" ]]; then
    persist_migration_master_key "$effective_key" \
      || die "Unable to persist the existing POLYNEXUS_MASTER_KEY to $MIGRATION_ENV_FILE."
  fi
}

declare -A CANDIDATES=()
add_candidate() {
  local candidate
  candidate="$(normalize_dir "$1")"
  if is_legacy_candidate "$candidate"; then
    CANDIDATES["$candidate"]=1
  fi
}

discover_from_processes() {
  local proc cmdline cwd exe_path
  for proc in /proc/[0-9]*; do
    [[ -r "$proc/cmdline" ]] || continue
    cmdline="$(tr '\0' ' ' < "$proc/cmdline" 2>/dev/null || true)"
    [[ "$cmdline" == *"$CLOUD_EXECUTABLE"* ]] || continue
    exe_path="$(printf '%s' "$cmdline" | grep -oE "/[^ ]*/${CLOUD_EXECUTABLE}" | head -n 1 || true)"
    [[ -n "$exe_path" ]] && add_candidate "$(dirname "$exe_path")"
    cwd="$(readlink -f "$proc/cwd" 2>/dev/null || true)"
    [[ -n "$cwd" ]] && add_candidate "$cwd"
  done
}

discover_from_files() {
  local root executable
  for root in /opt /www /srv /home /root; do
    [[ -d "$root" ]] || continue
    while IFS= read -r executable; do
      add_candidate "$(dirname "$executable")"
    done < <(find "$root" -xdev -type f -name "$CLOUD_EXECUTABLE" -perm /111 2>/dev/null || true)
  done
}

if [[ -n "$SOURCE_DIR" ]]; then
  SOURCE_DIR="$(normalize_dir "$SOURCE_DIR")"
  is_legacy_candidate "$SOURCE_DIR" || die "The specified directory is not a valid legacy $APP_NAME cloud installation: $SOURCE_DIR"
else
  discover_from_processes
  discover_from_files
  if [[ ${#CANDIDATES[@]} -ne 1 ]]; then
    printf 'Unable to select one legacy installation automatically. Valid candidates:\n' >&2
    for candidate in "${!CANDIDATES[@]}"; do printf '  %s\n' "$candidate" >&2; done
    die "Run again with --source-dir PATH."
  fi
  for candidate in "${!CANDIDATES[@]}"; do SOURCE_DIR="$candidate"; done
fi

TARGET_DIR="$SOURCE_DIR"
printf 'Migrating the verified legacy installation in place: %s\n' "$TARGET_DIR"

ACTIVE_PID=""
LEGACY_RUNTIME_PIDS=()
path_is_within_target() {
  case "$1" in
    "$TARGET_DIR"|"$TARGET_DIR"/*) return 0 ;;
    *) return 1 ;;
  esac
}
for proc in /proc/[0-9]*; do
  [[ -r "$proc/cmdline" ]] || continue
  cmdline="$(tr '\0' ' ' < "$proc/cmdline" 2>/dev/null || true)"
  [[ "$cmdline" == *"$CLOUD_EXECUTABLE"* ]] || continue
  cwd="$(readlink -f "$proc/cwd" 2>/dev/null || true)"
  exe_path="$(printf '%s' "$cmdline" | grep -oE "/[^ ]*/${CLOUD_EXECUTABLE}" | head -n 1 || true)"
  if path_is_within_target "$cwd" || { [[ -n "$exe_path" ]] && path_is_within_target "$exe_path"; }; then
    LEGACY_RUNTIME_PIDS+=("${proc##*/}")
    if [[ -z "$ACTIVE_PID" || "$cmdline" != *"--worker"* ]]; then
      ACTIVE_PID="${proc##*/}"
    fi
  fi
done

# Encrypted cloud credentials can only survive migration when the exact same
# master key survives it. Compare the caller, persisted environment file and
# the key actually inherited by the running legacy supervisor before writing
# any new-layout files.
RUNNING_MASTER_KEY="$(read_process_master_key "$ACTIVE_PID")"
LEGACY_HOST="$(read_process_argument "$ACTIVE_PID" --host)"
LEGACY_HOST="${LEGACY_HOST:-$(read_process_environment_value "$ACTIVE_PID" POLYNEXUS_HOST)}"
LEGACY_PORT="$(read_process_argument "$ACTIVE_PID" --port)"
LEGACY_PORT="${LEGACY_PORT:-$(read_process_environment_value "$ACTIVE_PID" POLYNEXUS_PORT)}"
LEGACY_RUNTIME_UID="$(read_process_uid "$ACTIVE_PID")"
LEGACY_RUNTIME_HOME="/root"
if [[ -n "$LEGACY_RUNTIME_UID" && "$LEGACY_RUNTIME_UID" != "0" ]]; then
  LEGACY_RUNTIME_USER="$(getent passwd "$LEGACY_RUNTIME_UID" 2>/dev/null | cut -d: -f1 || true)"
  LEGACY_RUNTIME_HOME="$(getent passwd "$LEGACY_RUNTIME_UID" 2>/dev/null | cut -d: -f6 || true)"
  LEGACY_RUNTIME_HOME="${LEGACY_RUNTIME_HOME:-/root}"
  printf '%s\n' \
    "Warning: the legacy runtime is owned by ${LEGACY_RUNTIME_USER:-UID $LEGACY_RUNTIME_UID}. The managed cloud runtime runs as root, so its user-scoped activation must be completed again after migration." \
    >&2
fi
verify_secret_storage_continuity "$TARGET_DIR/config.toml" "$RUNNING_MASTER_KEY"
verify_secret_storage_continuity "$TARGET_DIR/okx_futures.toml" "$RUNNING_MASTER_KEY"

LEGACY_EXECUTABLE="$TARGET_DIR/$CLOUD_EXECUTABLE"
LEGACY_EXECUTABLE_BACKUP="$TARGET_DIR/.${CLOUD_EXECUTABLE}.migration-backup"
LEGACY_RUNTIME_WAS_RUNNING=0
[[ ${#LEGACY_RUNTIME_PIDS[@]} -eq 0 ]] || LEGACY_RUNTIME_WAS_RUNNING=1
MIGRATION_SUCCEEDED=0
restore_legacy_runtime_on_failure() {
  local exit_code=$?
  if [[ "$MIGRATION_SUCCEEDED" != "1" ]]; then
    if [[ -f "$LEGACY_EXECUTABLE_BACKUP" && ! -e "$LEGACY_EXECUTABLE" ]]; then
      mv -f "$LEGACY_EXECUTABLE_BACKUP" "$LEGACY_EXECUTABLE" || true
      chmod 0755 "$LEGACY_EXECUTABLE" 2>/dev/null || true
    fi
    if [[ "$LEGACY_RUNTIME_WAS_RUNNING" == "1" && -x "$LEGACY_EXECUTABLE" ]]; then
      case "$SUPERVISOR_MODE" in
        systemd)
          systemctl restart "${POLYNEXUS_CLOUD_SERVICE:-${BRAND_ID}-cloud.service}" >/dev/null 2>&1 || true
          ;;
        standalone)
          nohup "$TARGET_DIR/bt-cloud-guard.sh" >/dev/null 2>&1 &
          ;;
        baota)
          # BaoTa owns restart policy and will observe the restored executable.
          ;;
      esac
    fi
  fi
  exit "$exit_code"
}
trap restore_legacy_runtime_on_failure EXIT

# Migration is deliberately offline. Rename the old executable before stopping
# it so BaoTa cannot immediately relaunch the flat-layout runtime while its
# SQLite files are being moved. A failed migration restores the executable.
[[ ! -e "$LEGACY_EXECUTABLE_BACKUP" ]] || die "A previous migration backup still exists: $LEGACY_EXECUTABLE_BACKUP"
mv "$LEGACY_EXECUTABLE" "$LEGACY_EXECUTABLE_BACKUP"
for legacy_pid in "${LEGACY_RUNTIME_PIDS[@]}"; do
  kill -TERM "$legacy_pid" 2>/dev/null || true
done
for ((attempt=0; attempt<60; attempt++)); do
  remaining=0
  for legacy_pid in "${LEGACY_RUNTIME_PIDS[@]}"; do
    if kill -0 "$legacy_pid" 2>/dev/null; then
      remaining=1
      break
    fi
  done
  [[ "$remaining" == "1" ]] || break
  sleep 0.5
done
for legacy_pid in "${LEGACY_RUNTIME_PIDS[@]}"; do
  if kill -0 "$legacy_pid" 2>/dev/null; then
    kill -KILL "$legacy_pid" 2>/dev/null || true
  fi
done
# Catch a runtime that a process supervisor launched during the stop boundary.
# The executable has already been renamed, so no further restart can succeed.
sleep 0.2
for proc in /proc/[0-9]*; do
  [[ -r "$proc/cmdline" ]] || continue
  cmdline="$(tr '\0' ' ' < "$proc/cmdline" 2>/dev/null || true)"
  [[ "$cmdline" == *"$CLOUD_EXECUTABLE"* ]] || continue
  cwd="$(readlink -f "$proc/cwd" 2>/dev/null || true)"
  exe_path="$(printf '%s' "$cmdline" | grep -oE "/[^ ]*/${CLOUD_EXECUTABLE}" | head -n 1 || true)"
  if path_is_within_target "$cwd" || { [[ -n "$exe_path" ]] && path_is_within_target "$exe_path"; }; then
    kill -KILL "${proc##*/}" 2>/dev/null || true
  fi
done
sleep 0.2

mkdir -p "$TARGET_DIR/shared"
for persistent_file in \
  config.toml \
  okx_futures.toml \
  cloud_web_auth.json \
  config.toml.cloud-automation-guard.json; do
  if [[ -f "$TARGET_DIR/$persistent_file" ]]; then
    cp -p "$TARGET_DIR/$persistent_file" "$TARGET_DIR/shared/$persistent_file"
    chmod 0600 "$TARGET_DIR/shared/$persistent_file"
  fi
done

LEGACY_PERSISTENCE_SOURCES=()
LEGACY_EPHEMERAL_SOURCES=()
declare -A STAGED_PERSISTENCE_PATHS=()
stage_legacy_persistence_path() {
  local source destination linked_target="" stage_key
  source="$(normalize_dir "$1")"
  destination="$(normalize_dir "$2")"
  [[ "$source" != "$destination" && -e "$source" ]] || return 0
  stage_key="$source|$destination"
  [[ -z "${STAGED_PERSISTENCE_PATHS[$stage_key]:-}" ]] || return 0
  STAGED_PERSISTENCE_PATHS["$stage_key"]=1
  mkdir -p "$(dirname "$destination")"
  if [[ -L "$destination" ]]; then
    linked_target="$(readlink -f "$destination" 2>/dev/null || true)"
    [[ "$linked_target" == "$source" ]] \
      || die "Existing migration link does not point to the legacy data: $destination"
    rm -f "$destination"
  elif [[ -e "$destination" ]]; then
    rm -rf -- "$destination"
  fi
  cp -a "$source" "$destination"
  LEGACY_PERSISTENCE_SOURCES+=("$source")
}

remove_legacy_persistence_sources() {
  local source cleanup_failed=0
  for source in "${LEGACY_PERSISTENCE_SOURCES[@]}"; do
    rm -rf -- "$source" || cleanup_failed=1
  done
  for source in "${LEGACY_EPHEMERAL_SOURCES[@]}"; do
    rm -f -- "$source" || cleanup_failed=1
  done
  return "$cleanup_failed"
}

remove_legacy_flat_layout_files() {
  local legacy_file stale_lock cleanup_failed=0
  # These files have authoritative replacements in shared or in the active
  # managed release. Remove them only after the new release has passed its
  # readiness check so the completed migration leaves one unambiguous copy.
  for legacy_file in \
    config.toml \
    okx_futures.toml \
    cloud_web_auth.json \
    config.toml.cloud-automation-guard.json \
    "${CLOUD_EXECUTABLE}.integrity.json"; do
    rm -f -- "$TARGET_DIR/$legacy_file" || cleanup_failed=1
  done

  # These log locks belong only to the flat-layout logger. Database locks are
  # registered from the actual migrated database paths below, so an absolute
  # database path that remains active is never deleted accidentally.
  for stale_lock in "$TARGET_DIR"/.cloud-*.log.lock; do
    [[ -e "$stale_lock" ]] || continue
    rm -f -- "$stale_lock" || cleanup_failed=1
  done
  return "$cleanup_failed"
}

read_toml_path_value() {
  local config_path="$1" section="$2" key="$3" raw=""
  [[ -f "$config_path" ]] || return 0
  raw="$(awk -v wanted_section="$section" -v wanted_key="$key" '
    /^[[:space:]]*\[[^]]+\][[:space:]]*$/ {
      current = $0
      sub(/^[[:space:]]*\[/, "", current)
      sub(/\][[:space:]]*$/, "", current)
      next
    }
    current == wanted_section && $0 ~ "^[[:space:]]*" wanted_key "[[:space:]]*=" {
      value = $0
      sub("^[[:space:]]*" wanted_key "[[:space:]]*=[[:space:]]*", "", value)
      print value
      exit
    }
  ' "$config_path")"
  raw="${raw#"${raw%%[![:space:]]*}"}"
  raw="${raw%"${raw##*[![:space:]]}"}"
  case "$raw" in
    \"*) raw="${raw#\"}"; raw="${raw%%\"*}" ;;
    \'*) raw="${raw#\'}"; raw="${raw%%\'*}" ;;
    *) raw="${raw%%#*}"; raw="${raw%"${raw##*[![:space:]]}"}" ;;
  esac
  printf '%s' "$raw"
}

resolve_configured_path() {
  local value="$1" config_path="$2" user_home="$3"
  case "$value" in
    /*) normalize_dir "$value" ;;
    '~') normalize_dir "$user_home" ;;
    '~/'*) normalize_dir "$user_home/${value#~/}" ;;
    *) normalize_dir "$(dirname "$config_path")/$value" ;;
  esac
}

rewrite_toml_path_value() {
  local config_path="$1" section="$2" key="$3" value="$4" temporary
  [[ -f "$config_path" ]] || return 0
  temporary="${config_path}.migration-new.$$"
  awk -v wanted_section="$section" -v wanted_key="$key" -v replacement="$value" '
    /^[[:space:]]*\[[^]]+\][[:space:]]*$/ {
      current = $0
      sub(/^[[:space:]]*\[/, "", current)
      sub(/\][[:space:]]*$/, "", current)
      print $0
      if (current == wanted_section) {
        printf "%s = \"%s\"\n", wanted_key, replacement
      }
      next
    }
    current == wanted_section && $0 ~ "^[[:space:]]*" wanted_key "[[:space:]]*=" { next }
    { print }
  ' "$config_path" > "$temporary"
  chmod 0600 "$temporary"
  mv -f "$temporary" "$config_path"
}

derived_sqlite_path() {
  local source="$1" marker="$2" directory name stem
  directory="$(dirname "$source")"
  name="$(basename "$source")"
  stem="${name%.*}"
  [[ "$stem" != "$name" ]] || stem="$name"
  normalize_dir "$directory/${stem}.${marker}.sqlite3"
}

derived_peer_path() {
  local source="$1" marker="$2" directory name stem suffix=""
  directory="$(dirname "$source")"
  name="$(basename "$source")"
  stem="${name%.*}"
  if [[ "$stem" != "$name" ]]; then
    suffix=".${name##*.}"
  else
    stem="$name"
  fi
  normalize_dir "$directory/${stem}.${marker}${suffix}"
}

stage_database_family() {
  local source="$1" destination="$2" suffix
  for suffix in '' -shm -wal; do
    stage_legacy_persistence_path "$source$suffix" "$destination$suffix"
  done
  stage_legacy_persistence_path "${source}.submitted-order-recovery" "${destination}.submitted-order-recovery"
  if [[ "$source" != "$destination" && -e "${source}.runtime.lock" ]]; then
    LEGACY_EPHEMERAL_SOURCES+=("${source}.runtime.lock")
  fi
}

stage_configured_databases() {
  local old_config="$TARGET_DIR/config.toml" new_config="$TARGET_DIR/shared/config.toml"
  local state_value l2_value old_state new_state old_l2 new_l2 old_twap new_twap
  local old_okx new_okx okx_value old_history new_history old_staging new_staging

  state_value="$(read_toml_path_value "$old_config" bot state_db_path)"
  state_value="${state_value:-bot_state.sqlite3}"
  old_state="$(resolve_configured_path "$state_value" "$old_config" "$LEGACY_RUNTIME_HOME")"
  new_state="$TARGET_DIR/shared/bot_state.sqlite3"
  stage_database_family "$old_state" "$new_state"

  l2_value="$(read_toml_path_value "$old_config" bot l2_shadow_db_path)"
  if [[ -n "$l2_value" ]]; then
    old_l2="$(resolve_configured_path "$l2_value" "$old_config" "$LEGACY_RUNTIME_HOME")"
  else
    old_l2="$(derived_sqlite_path "$old_state" l2-shadow)"
  fi
  new_l2="$TARGET_DIR/shared/bot_state.l2-shadow.sqlite3"
  stage_database_family "$old_l2" "$new_l2"
  old_history="$(derived_peer_path "$old_l2" history)"
  new_history="$(derived_peer_path "$new_l2" history)"
  stage_database_family "$old_history" "$new_history"
  old_staging="$(derived_peer_path "$old_l2" staging)"
  new_staging="$(derived_peer_path "$new_l2" staging)"
  stage_database_family "$old_staging" "$new_staging"

  old_twap="$(derived_sqlite_path "$old_state" twap60-shadow)"
  new_twap="$TARGET_DIR/shared/bot_state.twap60-shadow.sqlite3"
  stage_database_family "$old_twap" "$new_twap"

  rewrite_toml_path_value "$new_config" bot state_db_path "bot_state.sqlite3"
  rewrite_toml_path_value "$new_config" bot l2_shadow_db_path ""

  if [[ -f "$TARGET_DIR/okx_futures.toml" ]]; then
    okx_value="$(read_toml_path_value "$TARGET_DIR/okx_futures.toml" okx state_db_path)"
    okx_value="${okx_value:-bot_state.okx-futures.sqlite3}"
    old_okx="$(resolve_configured_path "$okx_value" "$TARGET_DIR/okx_futures.toml" "$LEGACY_RUNTIME_HOME")"
    new_okx="$TARGET_DIR/shared/bot_state.okx-futures.sqlite3"
    stage_database_family "$old_okx" "$new_okx"
    rewrite_toml_path_value "$TARGET_DIR/shared/okx_futures.toml" okx state_db_path "bot_state.okx-futures.sqlite3"
  fi
}

stage_legacy_logs() {
  local legacy_log_dir source
  mkdir -p "$TARGET_DIR/shared/logs"
  # Older packages used both log/ and logs/. Merge their retained history into
  # the single managed shared/logs directory while the legacy runtime is down.
  for legacy_log_dir in "$TARGET_DIR/log" "$TARGET_DIR/logs"; do
    [[ -d "$legacy_log_dir" ]] || continue
    cp -a "$legacy_log_dir/." "$TARGET_DIR/shared/logs/"
    LEGACY_PERSISTENCE_SOURCES+=("$legacy_log_dir")
  done
  shopt -s nullglob
  for source in \
    "$TARGET_DIR"/cloud-debug*.log \
    "$TARGET_DIR"/cloud-fault*.log \
    "$TARGET_DIR"/cloud-startup*.log \
    "$TARGET_DIR"/guard.out.log; do
    [[ -f "$source" ]] || continue
    stage_legacy_persistence_path "$source" "$TARGET_DIR/shared/logs/$(basename "$source")"
  done
  shopt -u nullglob
}

# The old runtime is stopped above, so configured databases are copied as real
# files under shared. The copied configs are rewritten to the standard relative
# names, so legacy relative, absolute and custom-suffix paths all converge on
# the managed layout without symlinks.
stage_configured_databases
stage_legacy_logs

# Wallet-vault delivery state is outside the installation directory and its
# file name is keyed by the absolute config path. Bridge the old flat config
# identity to shared/config.toml once so an encrypted pending envelope and the
# device signing identity survive this one-time migration. Normal installs and
# updates never need this compatibility step.
migrate_wallet_vault_runtime_state() {
  local legacy_state_home="$1" managed_state_home="$2"
  local legacy_state_dir managed_state_dir
  local old_config new_config old_identity new_identity old_path new_path suffix
  legacy_state_home="$(normalize_dir "$legacy_state_home")"
  managed_state_home="$(normalize_dir "$managed_state_home")"
  legacy_state_dir="$legacy_state_home/${BRAND_ID}/runtime-state"
  managed_state_dir="$managed_state_home/${BRAND_ID}/runtime-state"
  old_config="$(normalize_dir "$TARGET_DIR/config.toml")"
  new_config="$(normalize_dir "$TARGET_DIR/shared/config.toml")"
  old_identity="$(printf '%s' "$old_config" | sha256sum | awk '{print $1}')"
  new_identity="$(printf '%s' "$new_config" | sha256sum | awk '{print $1}')"
  [[ "$old_identity" != "$new_identity" && -d "$legacy_state_dir" ]] || return 0
  mkdir -p "$managed_state_dir"
  chmod 0700 "$managed_state_dir" 2>/dev/null || true
  for suffix in pending device; do
    if [[ "$suffix" == "pending" ]]; then
      old_path="$legacy_state_dir/.pending-${old_identity}.dat"
      new_path="$managed_state_dir/.pending-${new_identity}.dat"
    else
      old_path="$legacy_state_dir/.device-${old_identity}.dat.key"
      new_path="$managed_state_dir/.device-${new_identity}.dat.key"
    fi
    if [[ -L "$new_path" && "$(readlink -f "$new_path" 2>/dev/null || true)" == "$old_path" ]]; then
      rm -f "$new_path"
    fi
    if [[ -e "$old_path" && ! -e "$new_path" ]]; then
      cp -p "$old_path" "$new_path"
    fi
  done
}

RUNNING_XDG_STATE_HOME="$(read_process_environment_value "$ACTIVE_PID" XDG_STATE_HOME)"
RUNNING_HOME="$(read_process_environment_value "$ACTIVE_PID" HOME)"
PERSISTED_XDG_STATE_HOME="$(read_persisted_runtime_value XDG_STATE_HOME)"
MANAGED_STATE_HOME="${PERSISTED_XDG_STATE_HOME:-/root/.local/state}"
if [[ -n "$RUNNING_XDG_STATE_HOME" ]]; then
  LEGACY_STATE_HOME="$RUNNING_XDG_STATE_HOME"
elif [[ -n "$RUNNING_HOME" ]]; then
  LEGACY_STATE_HOME="$RUNNING_HOME/.local/state"
else
  LEGACY_STATE_HOME="$MANAGED_STATE_HOME"
fi
migrate_wallet_vault_runtime_state "$LEGACY_STATE_HOME" "$MANAGED_STATE_HOME"

# Legacy builds did not consistently publish a machine-readable version. They
# are therefore never registered as a rollback release. The old executable is
# used only to verify that the selected directory is a genuine legacy install;
# persistent files are migrated above and the standard installer now downloads
# the latest verified GitHub Release as the first managed software version.
rm -f "$TARGET_DIR/current.migration"

INSTALLER_PATH="$TARGET_DIR/install-cloud.sh"
if [[ -n "$INSTALLER_SOURCE" ]]; then
  INSTALLER_SOURCE="$(normalize_dir "$INSTALLER_SOURCE")"
  [[ -f "$INSTALLER_SOURCE" ]] || die "Installer script not found: $INSTALLER_SOURCE"
  cp "$INSTALLER_SOURCE" "$INSTALLER_PATH.new"
else
  curl --fail --location --connect-timeout 10 --max-time 30 \
    -o "$INSTALLER_PATH.new" "https://raw.githubusercontent.com/${RELEASE_REPO}/main/install-cloud.sh"
fi
chmod 0755 "$INSTALLER_PATH.new"
mv -f "$INSTALLER_PATH.new" "$INSTALLER_PATH"

export POLYNEXUS_INSTALL_ROOT="$TARGET_DIR"
[[ -z "$LEGACY_HOST" ]] || export POLYNEXUS_HOST="$LEGACY_HOST"
[[ -z "$LEGACY_PORT" ]] || export POLYNEXUS_PORT="$LEGACY_PORT"
bash "$INSTALLER_PATH" --install-dir "$TARGET_DIR" --supervisor "$SUPERVISOR_MODE" install
# The standard installer returns only after the managed release is healthy.
# From this point forward the migration is committed: cleanup must never revive
# the flat-layout executable beside an already-running managed release.
MIGRATION_SUCCEEDED=1
cleanup_warning=0
remove_legacy_persistence_sources || cleanup_warning=1
remove_legacy_flat_layout_files || cleanup_warning=1
rm -f "$LEGACY_EXECUTABLE_BACKUP" || cleanup_warning=1
if [[ "$cleanup_warning" == "1" ]]; then
  printf '%s\n' "Warning: migration is active, but some legacy files could not be removed. The managed release remains authoritative." >&2
fi
printf '%s legacy migration completed. Future updates use %s only.\n' "$APP_NAME" "$INSTALLER_PATH"
