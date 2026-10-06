#!/usr/bin/env bash
set -euo pipefail
umask 077

# Stable installer/updater. The Polymarket public repository receives this file
# with the five brand constants below rendered for that brand.
BRAND_ID="${POLYNEXUS_UPDATE_BRAND_ID:-polymarket}"
APP_NAME="${POLYNEXUS_UPDATE_APP_NAME:-Polymarket}"
RELEASE_REPO="${POLYNEXUS_UPDATE_RELEASE_REPO:-naka2027/polymarket-bot}"
CLOUD_EXECUTABLE="${POLYNEXUS_UPDATE_CLOUD_EXECUTABLE:-PolymarketCloud}"
CLOUD_ARCHIVE="${POLYNEXUS_UPDATE_CLOUD_ARCHIVE:-PolymarketCloud-linux-x64-centos7.tar.gz}"

die() { printf '%s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Required command is missing: $1"; }
[[ "$EUID" -eq 0 ]] || die "Run the cloud installer as root, for example with sudo."

# BASH_SOURCE has no element when the public installer is streamed into
# `bash -s`. Treat that as an intentional remote bootstrap; persist_installer
# will download the stable copy into the selected installation root.
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [[ -f "$SCRIPT_SOURCE" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd -P)"
fi

bootstrap_is_valid() {
  local candidate="$1"
  bash -n "$candidate" \
    && grep -Fq "$RELEASE_REPO" "$candidate" \
    && grep -Fq "$CLOUD_EXECUTABLE" "$candidate" \
    && grep -Fq "$CLOUD_ARCHIVE" "$candidate"
}

# An installed copy is a stable bootstrap kept in the public brand repository.
# Refresh it before mutating the installation so future maintenance fixes do
# not depend on shipping the helper inside every application archive.
ORIGINAL_ARGS=("$@")
refresh_installed_bootstrap() {
  [[ "${POLYNEXUS_INSTALLER_REFRESHED:-0}" != "1" ]] || return 0
  [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/.cloud-install-root" ]] || return 0
  local installed_brand=""
  installed_brand="$(tr -d '\r\n' < "$SCRIPT_DIR/.cloud-install-root")"
  # Do not let a wrong-brand bootstrap overwrite this installation.  The
  # command-specific identity check below will publish the normal failed state
  # once apply-release has parsed its job metadata.
  [[ "$installed_brand" == "$BRAND_ID" ]] || return 0
  for argument in "${ORIGINAL_ARGS[@]}"; do
    [[ "$argument" != "status" ]] || return 0
  done
  command -v curl >/dev/null 2>&1 || return 0
  local destination="$SCRIPT_DIR/install-cloud.sh" temporary="$SCRIPT_DIR/.install-cloud.refresh.$$"
  if ! curl --fail --silent --show-error --location --connect-timeout 10 --max-time 30 \
    -o "$temporary" "https://raw.githubusercontent.com/${RELEASE_REPO}/main/install-cloud.sh"; then
    rm -f "$temporary"
    printf '%s\n' "Warning: unable to refresh install-cloud.sh; continuing with the installed bootstrap." >&2
    return 0
  fi
  if ! bootstrap_is_valid "$temporary"; then
    rm -f "$temporary"
    printf '%s\n' "Warning: refreshed install-cloud.sh failed validation; continuing with the installed bootstrap." >&2
    return 0
  fi
  chmod 0755 "$temporary"
  if [[ -f "$destination" ]] && cmp -s "$temporary" "$destination"; then
    rm -f "$temporary"
    return 0
  fi
  mv -f "$temporary" "$destination"
  exec env \
    POLYNEXUS_INSTALLER_REFRESHED=1 \
    POLYNEXUS_INSTALL_ROOT="$SCRIPT_DIR" \
    bash "$destination" "${ORIGINAL_ARGS[@]}"
}
refresh_installed_bootstrap

# --install-dir is accepted by every command. Once installed, the script's
# directory is authoritative, so custom roots never have to be rediscovered.
REQUESTED_INSTALL_ROOT="${POLYNEXUS_INSTALL_ROOT:-}"
SUPERVISOR_MODE="${POLYNEXUS_CLOUD_SUPERVISOR:-}"
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-dir)
      [[ $# -ge 2 ]] || die "--install-dir requires a path."
      REQUESTED_INSTALL_ROOT="$2"
      shift 2
      ;;
    --supervisor)
      [[ $# -ge 2 ]] || die "--supervisor requires auto, systemd, baota or standalone."
      SUPERVISOR_MODE="$2"
      shift 2
      ;;
    *) POSITIONAL_ARGS+=("$1"); shift ;;
  esac
done
set -- "${POSITIONAL_ARGS[@]}"

if [[ -z "$REQUESTED_INSTALL_ROOT" && -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/.cloud-install-root" ]]; then
  REQUESTED_INSTALL_ROOT="$SCRIPT_DIR"
fi
INSTALL_ROOT="${REQUESTED_INSTALL_ROOT:-/opt/${BRAND_ID}-cloud}"
if command -v realpath >/dev/null 2>&1; then
  INSTALL_ROOT="$(realpath -m "$INSTALL_ROOT")"
elif command -v readlink >/dev/null 2>&1; then
  INSTALL_ROOT="$(readlink -m "$INSTALL_ROOT")"
fi
[[ "$INSTALL_ROOT" == /* ]] || die "The installation directory must resolve to an absolute path."
case "$INSTALL_ROOT" in
  /|/bin|/boot|/dev|/etc|/home|/lib|/lib64|/opt|/proc|/root|/run|/sbin|/srv|/sys|/tmp|/usr|/var)
    die "Unsafe installation directory: $INSTALL_ROOT"
    ;;
esac

RELEASES_DIR="$INSTALL_ROOT/releases"
SHARED_DIR="$INSTALL_ROOT/shared"
STAGING_DIR="$INSTALL_ROOT/staging"
CURRENT_LINK="$INSTALL_ROOT/current"
PREVIOUS_LINK="$INSTALL_ROOT/previous"
MAINTENANCE_MARKER="$INSTALL_ROOT/.update-maintenance"
DEFAULT_STATE_FILE="$SHARED_DIR/update-status.json"
if [[ -z "$SUPERVISOR_MODE" && -f "$INSTALL_ROOT/.cloud-supervisor" ]]; then
  SUPERVISOR_MODE="$(tr -d '\r\n' < "$INSTALL_ROOT/.cloud-supervisor")"
fi
SUPERVISOR_MODE="${SUPERVISOR_MODE:-auto}"
[[ "$SUPERVISOR_MODE" =~ ^(auto|systemd|baota|standalone)$ ]] || die "Invalid supervisor mode: $SUPERVISOR_MODE"

json_escape() {
  local value="${1:-}"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/ }"
  printf '%s' "$value"
}

pid_start_time() {
  local pid="$1" stat_line="" stat_fields=""
  [[ "$pid" =~ ^[0-9]+$ && -r "/proc/$pid/stat" ]] || return 1
  IFS= read -r stat_line < "/proc/$pid/stat" || return 1
  stat_fields="${stat_line##*) }"
  awk '{print $20}' <<< "$stat_fields"
}

process_identity_token() {
  local pid="$1" start_time="" boot_id=""
  start_time="$(pid_start_time "$pid" 2>/dev/null || true)"
  [[ -n "$start_time" && -r /proc/sys/kernel/random/boot_id ]] || return 1
  boot_id="$(tr -d '\r\n' < /proc/sys/kernel/random/boot_id)"
  [[ -n "$boot_id" ]] || return 1
  printf 'linux:%s:%s' "$boot_id" "$start_time"
}

running_runtime_argument() {
  local wanted="$1" pid="" recorded_start="" actual_start="" argument="" return_next=0
  [[ -r "$INSTALL_ROOT/runtime.pid" ]] || return 0
  read -r pid recorded_start < "$INSTALL_ROOT/runtime.pid" || return 0
  [[ "$pid" =~ ^[0-9]+$ && -r "/proc/$pid/cmdline" ]] || return 0
  actual_start="$(pid_start_time "$pid" 2>/dev/null || true)"
  [[ -n "$actual_start" && "$actual_start" == "$recorded_start" ]] || return 0
  while IFS= read -r -d '' argument; do
    if [[ "$return_next" == "1" ]]; then
      printf '%s' "$argument"
      return 0
    fi
    [[ "$argument" == "$wanted" ]] && return_next=1
  done < "/proc/$pid/cmdline"
}

persisted_runtime_argument() {
  local wanted="$1" runtime_env="$INSTALL_ROOT/.cloud-runtime.env"
  [[ -f "$runtime_env" ]] || return 0
  (
    unset POLYNEXUS_HOST POLYNEXUS_PORT POLYNEXUS_ENV_FILE POLYNEXUS_CLOUD_SERVICE
    set -a
    # This root-owned file is written atomically by configure_supervisor.
    # shellcheck disable=SC1090
    source "$runtime_env"
    set +a
    case "$wanted" in
      --host) printf '%s' "${POLYNEXUS_HOST:-}" ;;
      --port) printf '%s' "${POLYNEXUS_PORT:-}" ;;
      --env-file) printf '%s' "${POLYNEXUS_ENV_FILE:-}" ;;
      --service) printf '%s' "${POLYNEXUS_CLOUD_SERVICE:-}" ;;
    esac
  ) 2>/dev/null || true
}

RUNNING_HOST="$(running_runtime_argument --host)"
RUNNING_PORT="$(running_runtime_argument --port)"
PERSISTED_HOST="$(persisted_runtime_argument --host)"
PERSISTED_PORT="$(persisted_runtime_argument --port)"
PERSISTED_ENV_FILE="$(persisted_runtime_argument --env-file)"
PERSISTED_CLOUD_SERVICE="$(persisted_runtime_argument --service)"
DEFAULT_HOST="${POLYNEXUS_HOST:-${RUNNING_HOST:-${PERSISTED_HOST:-127.0.0.1}}}"
DEFAULT_PORT="${POLYNEXUS_PORT:-${RUNNING_PORT:-${PERSISTED_PORT:-8765}}}"
DEFAULT_ENV_FILE="${POLYNEXUS_ENV_FILE:-${PERSISTED_ENV_FILE:-/etc/${BRAND_ID}/cloud.env}}"
DEFAULT_CLOUD_SERVICE="${POLYNEXUS_CLOUD_SERVICE:-${PERSISTED_CLOUD_SERVICE:-${BRAND_ID}-cloud.service}}"
[[ "$DEFAULT_HOST" =~ ^[A-Za-z0-9._:-]+$ ]] || die "The cloud host contains unsupported characters."
[[ "$DEFAULT_PORT" =~ ^[0-9]+$ ]] || die "The cloud port must be numeric."
DEFAULT_PORT_NUMBER=$((10#$DEFAULT_PORT))
(( DEFAULT_PORT_NUMBER >= 1 && DEFAULT_PORT_NUMBER <= 65535 )) || die "The cloud port must be between 1 and 65535."

begin_maintenance() {
  local token="" temporary="${MAINTENANCE_MARKER}.new.$$"
  token="$(process_identity_token "$$")" || die "Unable to establish the updater process identity."
  umask 077
  printf '%s %s\n' "$$" "$token" > "$temporary"
  mv -f "$temporary" "$MAINTENANCE_MARKER"
}

end_maintenance() {
  rm -f "$MAINTENANCE_MARKER"
}

write_status() {
  local state_file="$1" job_id="$2" status="$3" progress="$4" message="$5" version="$6"
  local tmp_file="${state_file}.tmp.$$" process_token=""
  process_token="$(process_identity_token "$$" 2>/dev/null || true)"
  mkdir -p "$(dirname "$state_file")"
  umask 077
  printf '{"job_id":"%s","status":"%s","progress":%s,"message":"%s","target_version":"%s","runtime_component":"cloud-web","maintainer_pid":%s,"maintainer_process_token":"%s","updated_at":"%s"}\n' \
    "$(json_escape "$job_id")" "$(json_escape "$status")" "$progress" "$(json_escape "$message")" \
    "$(json_escape "$version")" "$$" "$(json_escape "$process_token")" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$tmp_file"
  mv -f "$tmp_file" "$state_file"
}

current_health_body() {
  curl -sS --max-time 2 "http://${DEFAULT_HOST}:${DEFAULT_PORT}/api/health" 2>/dev/null || true
}

health_version_from_body() {
  printf '%s' "$1" | sed -n 's/.*"app_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

health_status_from_body() {
  printf '%s' "$1" | sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

health_identity_matches() {
  local body="$1" brand component
  brand="$(printf '%s' "$body" | sed -n 's/.*"brand_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  component="$(printf '%s' "$body" | sed -n 's/.*"runtime_component"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  [[ "$brand" == "$BRAND_ID" && "$component" == "cloud-web" ]]
}

current_process_version() {
  local body
  body="$(current_health_body)"
  health_identity_matches "$body" || return 0
  health_version_from_body "$body"
}

current_health_version() {
  local body version status
  body="$(current_health_body)"
  health_identity_matches "$body" || return 0
  version="$(health_version_from_body "$body")"
  status="$(health_status_from_body "$body")"
  case "$status" in
    ready|activation_required|cloud_auth_setup_required|cloud_auth_login_required)
      printf '%s' "$version"
      ;;
  esac
}

wait_for_version() {
  local expected_version="$1" attempts="${2:-80}" health_version
  for ((index=0; index<attempts; index++)); do
    health_version="$(current_health_version)"
    if [[ "$health_version" == "$expected_version" ]]; then
      return 0
    fi
    sleep 1.5
  done
  return 1
}

validate_archive() {
  local archive="$1"
  tar -tzf "$archive" | while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    [[ "$entry" != /* ]] || die "Release archive contains an absolute path."
    [[ "/$entry/" != *"/../"* ]] || die "Release archive contains a parent traversal path."
  done
  if tar -tvzf "$archive" | awk 'substr($1,1,1)=="l" || substr($1,1,1)=="h" {found=1} END {exit !found}'; then
    die "Release archive contains links and was rejected."
  fi
}

verify_packaged_executable() {
  local release_dir expected_version executable
  release_dir="$1"
  expected_version="$2"
  executable="$release_dir/$CLOUD_EXECUTABLE"
  local manifest="$release_dir/${CLOUD_EXECUTABLE}.integrity.json" expected actual packaged_version
  [[ -f "$executable" ]] || die "Cloud executable is missing from the release archive."
  [[ -f "$manifest" ]] || die "Signed integrity manifest is missing from the release archive."
  expected="$(sed -n 's/.*"sha256"[[:space:]]*:[[:space:]]*"\([0-9a-fA-F]\{64\}\)".*/\1/p' "$manifest" | head -n 1 | tr 'A-F' 'a-f')"
  [[ "$expected" =~ ^[0-9a-f]{64}$ ]] || die "Signed integrity manifest does not contain a valid SHA-256 digest."
  actual="$(sha256sum "$executable" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || die "Cloud executable does not match its signed integrity manifest."
  packaged_version="$(sed -n 's/.*"app_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | head -n 1)"
  [[ -n "$packaged_version" ]] || die "Signed integrity manifest does not contain an application version."
  [[ "$packaged_version" == "$expected_version" ]] || die "Release tag and packaged application version do not match."
  chmod 0755 "$executable"
}

release_identity_version() {
  local release_dir executable
  release_dir="$1"
  executable="$release_dir/$CLOUD_EXECUTABLE"
  local manifest="$release_dir/${CLOUD_EXECUTABLE}.integrity.json" expected actual version recorded_version
  [[ -f "$executable" && -f "$manifest" ]] || return 1
  expected="$(sed -n 's/.*"sha256"[[:space:]]*:[[:space:]]*"\([0-9a-fA-F]\{64\}\)".*/\1/p' "$manifest" | head -n 1 | tr 'A-F' 'a-f')"
  [[ "$expected" =~ ^[0-9a-f]{64}$ ]] || return 1
  actual="$(sha256sum "$executable" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || return 1
  version="$(sed -n 's/.*"app_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | head -n 1)"
  if [[ -z "$version" && -f "$release_dir/.app-version" ]]; then
    recorded_version="$(tr -d '\r\n' < "$release_dir/.app-version")"
    if [[ "$recorded_version" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
      version="$recorded_version"
    fi
  fi
  [[ -n "$version" ]] || return 1
  printf '%s' "$version"
}

version_is_newer() {
  local candidate="$1" current="$2" newest
  [[ "$candidate" =~ ^[0-9]+(\.[0-9]+)+$ ]] || return 1
  [[ "$current" =~ ^[0-9]+(\.[0-9]+)+$ ]] || return 1
  [[ "$candidate" != "$current" ]] || return 1
  newest="$(printf '%s\n%s\n' "$current" "$candidate" | sort -V | tail -n 1)"
  [[ "$newest" == "$candidate" ]]
}

release_guard_is_valid() {
  local release_dir guard
  release_dir="$1"
  guard="$release_dir/bt-cloud-guard.sh"
  [[ -f "$guard" ]] || return 1
  bash -n "$guard" >/dev/null 2>&1
}

install_guard_from_release() {
  local release_dir source
  release_dir="$1"
  source="$release_dir/bt-cloud-guard.sh"
  local temporary="$INSTALL_ROOT/bt-cloud-guard.sh.new.$$"
  release_guard_is_valid "$release_dir" || die "Cloud guard is missing or invalid in release: $release_dir"
  cp "$source" "$temporary"
  chmod 0755 "$temporary"
  mv -f "$temporary" "$INSTALL_ROOT/bt-cloud-guard.sh"
}

stop_pid_and_wait() {
  local pid="$1" expected_start="${2:-}" actual_start=""
  [[ "$pid" =~ ^[0-9]+$ ]] || return 0
  kill -0 "$pid" 2>/dev/null || return 0
  if [[ -n "$expected_start" ]]; then
    actual_start="$(pid_start_time "$pid" 2>/dev/null || true)"
    [[ -n "$actual_start" && "$actual_start" == "$expected_start" ]] || return 0
  fi
  kill -TERM "$pid" 2>/dev/null || true
  for ((attempt=0; attempt<60; attempt++)); do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 0.5
  done
  kill -KILL "$pid" 2>/dev/null || true
  for ((attempt=0; attempt<10; attempt++)); do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 0.2
  done
  die "Cloud runtime process $pid did not stop."
}

stop_current_runtime() {
  local supervisor_pid="${POLYNEXUS_RUNTIME_SUPERVISOR_PID:-}" pid_file="$INSTALL_ROOT/runtime.pid"
  if [[ "$supervisor_pid" =~ ^[0-9]+$ ]] && kill -0 "$supervisor_pid" 2>/dev/null; then
    stop_pid_and_wait "$supervisor_pid"
  fi
  if [[ -f "$pid_file" ]]; then
    local pid="" start_time=""
    read -r pid start_time < "$pid_file" || true
    stop_pid_and_wait "$pid" "$start_time"
    rm -f "$pid_file"
  fi
}

start_runtime() {
  local allow_supervisor_grace="${1:-1}"
  local service_name="$DEFAULT_CLOUD_SERVICE"
  if [[ "$SUPERVISOR_MODE" == "systemd" ]] && command -v systemctl >/dev/null 2>&1; then
    systemctl restart "$service_name" >/dev/null 2>&1 || true
    return 0
  fi
  # Give BaoTa or another external supervisor the first opportunity to restart
  # the stable guard path. The guard's runtime lock prevents duplicate runtimes.
  if [[ "$SUPERVISOR_MODE" == "baota" && "$allow_supervisor_grace" == "1" ]]; then
    for ((attempt=0; attempt<10; attempt++)); do
      [[ -n "$(current_health_version)" ]] && return 0
      sleep 1
    done
  fi
  [[ -x "$INSTALL_ROOT/bt-cloud-guard.sh" ]] || die "Cloud guard is missing."
  mkdir -p "$SHARED_DIR/logs"
  nohup "$INSTALL_ROOT/bt-cloud-guard.sh" > "$SHARED_DIR/logs/guard.out.log" 2>&1 &
}

deactivate_failed_first_release() {
  local service_name="$DEFAULT_CLOUD_SERVICE"
  begin_maintenance
  if [[ "$SUPERVISOR_MODE" == "systemd" ]] && command -v systemctl >/dev/null 2>&1; then
    systemctl stop "$service_name" >/dev/null 2>&1 || true
    systemctl disable "$service_name" >/dev/null 2>&1 || true
  fi
  stop_current_runtime
  rm -f "$CURRENT_LINK"
  end_maintenance
}

persist_runtime_settings() {
  local destination="$INSTALL_ROOT/.cloud-runtime.env" temporary
  temporary="${destination}.new.$$"
  printf 'POLYNEXUS_HOST=%q\nPOLYNEXUS_PORT=%q\nPOLYNEXUS_ENV_FILE=%q\nPOLYNEXUS_CLOUD_SERVICE=%q\n' \
    "$DEFAULT_HOST" "$DEFAULT_PORT" "$DEFAULT_ENV_FILE" "$DEFAULT_CLOUD_SERVICE" \
    > "$temporary" || return 1
  chmod 0600 "$temporary" || { rm -f "$temporary"; return 1; }
  mv -f "$temporary" "$destination" || { rm -f "$temporary"; return 1; }
}

configure_supervisor() {
  local service_name="$DEFAULT_CLOUD_SERVICE"
  if [[ "$SUPERVISOR_MODE" == "auto" ]]; then
    if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
      SUPERVISOR_MODE="systemd"
    else
      SUPERVISOR_MODE="standalone"
    fi
  fi
  persist_runtime_settings || return 1
  if [[ "$SUPERVISOR_MODE" != "systemd" ]]; then
    printf '%s\n' "$SUPERVISOR_MODE" > "$INSTALL_ROOT/.cloud-supervisor" || return 1
    return 0
  fi
  command -v systemctl >/dev/null 2>&1 || die "systemd supervisor was requested but systemctl is unavailable."
  [[ -d /run/systemd/system ]] || die "systemd supervisor was requested but systemd is not running."
  [[ "$INSTALL_ROOT" != *[$'\n\r\t ']* && "$INSTALL_ROOT" != *%* ]] || die "The systemd installation path cannot contain whitespace or percent signs."
  printf '%s\n' "$SUPERVISOR_MODE" > "$INSTALL_ROOT/.cloud-supervisor" || return 1
  local unit_path="/etc/systemd/system/$service_name"
  if ! cat > "$unit_path" <<EOF
[Unit]
Description=$APP_NAME Cloud
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$INSTALL_ROOT
Environment=POLYNEXUS_HOST=$DEFAULT_HOST
Environment=POLYNEXUS_PORT=$DEFAULT_PORT
ExecStart=$INSTALL_ROOT/bt-cloud-guard.sh
Restart=always
RestartSec=2
KillMode=control-group

[Install]
WantedBy=multi-user.target
EOF
  then
    return 1
  fi
  systemctl daemon-reload || return 1
}

finalize_supervisor() {
  local service_name="$DEFAULT_CLOUD_SERVICE"
  if [[ "$SUPERVISOR_MODE" == "systemd" ]]; then
    # A fresh unit is made persistent only after the runtime proves healthy.
    # Existing enabled units remain enabled throughout an ordinary update.
    systemctl enable "$service_name" >/dev/null
  fi
}

persist_installer() {
  local destination temporary
  destination="$INSTALL_ROOT/install-cloud.sh"
  temporary="${destination}.new.$$"
  mkdir -p "$INSTALL_ROOT"
  if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_SOURCE" ]]; then
    if [[ "$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd -P)/$(basename "$SCRIPT_SOURCE")" != "$destination" ]]; then
      cp "$SCRIPT_SOURCE" "$temporary"
      chmod 0755 "$temporary"
      mv -f "$temporary" "$destination"
    else
      chmod 0755 "$destination"
    fi
  else
    curl --fail --location --connect-timeout 10 --max-time 30 -o "$temporary" \
      "https://raw.githubusercontent.com/${RELEASE_REPO}/main/install-cloud.sh"
    if ! bootstrap_is_valid "$temporary"; then
      rm -f "$temporary"
      die "Downloaded cloud bootstrap failed identity or syntax validation."
    fi
    chmod 0755 "$temporary"
    mv -f "$temporary" "$destination"
  fi
}

mark_install_root() {
  local marker temporary
  marker="$INSTALL_ROOT/.cloud-install-root"
  temporary="${marker}.new.$$"
  printf '%s\n' "$BRAND_ID" > "$temporary"
  chmod 0600 "$temporary"
  mv -f "$temporary" "$marker"
}

validate_install_root_identity() {
  local marker="$INSTALL_ROOT/.cloud-install-root" installed_brand=""
  INSTALL_ROOT_IDENTITY_ERROR=""
  if [[ -f "$marker" ]]; then
    installed_brand="$(tr -d '\r\n' < "$marker")"
    if [[ "$installed_brand" != "$BRAND_ID" ]]; then
      INSTALL_ROOT_IDENTITY_ERROR="Installation brand mismatch: expected $BRAND_ID, found ${installed_brand:-unknown}."
      return 1
    fi
    return 0
  fi
  if [[ -x "$INSTALL_ROOT/$CLOUD_EXECUTABLE" && -f "$INSTALL_ROOT/config.toml" ]]; then
    INSTALL_ROOT_IDENTITY_ERROR="A legacy flat-layout installation exists in $INSTALL_ROOT. Run the separate migrate-cloud.sh helper instead."
    return 1
  fi
}

fail_apply_preflight() {
  local state_file="$1" job_id="$2" version="$3" message="$4"
  # The dashboard has already created this job's state file.  Only update an
  # absent file or the same job; never replace a concurrent maintainer's state.
  if [[ ! -f "$state_file" ]] \
    || grep -Eq '"job_id"[[:space:]]*:[[:space:]]*"'"$job_id"'"' "$state_file" 2>/dev/null; then
    write_status "$state_file" "$job_id" "failed" 100 "$message" "$version" || true
  fi
  die "$message"
}

prune_installation_artifacts() {
  local current_target="" previous_target="" candidate resolved
  current_target="$(readlink -f "$CURRENT_LINK" 2>/dev/null || true)"
  previous_target="$(readlink -f "$PREVIOUS_LINK" 2>/dev/null || true)"
  if [[ -d "$RELEASES_DIR" ]]; then
    for candidate in "$RELEASES_DIR"/*; do
      [[ -d "$candidate" ]] || continue
      resolved="$(readlink -f "$candidate" 2>/dev/null || true)"
      [[ "$resolved" == "$current_target" || "$resolved" == "$previous_target" ]] && continue
      rm -rf "$candidate"
    done
  fi
  find "$STAGING_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf -- {} + 2>/dev/null || true
}

apply_release() {
  local job_id="" state_file="$DEFAULT_STATE_FILE" version="" asset_url="" asset_name="" expected_sha=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --job-id) job_id="$2"; shift 2 ;;
      --state-file) state_file="$2"; shift 2 ;;
      --version) version="$2"; shift 2 ;;
      --asset-url) asset_url="$2"; shift 2 ;;
      --asset-name) asset_name="$2"; shift 2 ;;
      --sha256) expected_sha="$2"; shift 2 ;;
      *) die "Unknown apply-release argument: $1" ;;
    esac
  done
  [[ "$job_id" =~ ^[A-Za-z0-9._-]{1,96}$ && "$job_id" != "." && "$job_id" != ".." ]] || die "Invalid update job id."
  [[ "$version" =~ ^[0-9]+(\.[0-9]+)+$ ]] || die "Invalid release version."
  [[ "$asset_name" == "$CLOUD_ARCHIVE" ]] || die "Unexpected cloud release asset."
  [[ "$asset_url" == "https://github.com/${RELEASE_REPO}/releases/download/"*"/${CLOUD_ARCHIVE}" ]] || die "Unexpected release download URL."
  [[ -z "$expected_sha" || "$expected_sha" =~ ^[0-9a-fA-F]{64}$ ]] || die "Invalid release SHA-256 digest."
  if ! validate_install_root_identity; then
    fail_apply_preflight "$state_file" "$job_id" "$version" "$INSTALL_ROOT_IDENTITY_ERROR"
  fi

  apply_release_exit() {
    local exit_code=$?
    end_maintenance
    if [[ $exit_code -ne 0 ]] && ! grep -Eq '"status":"(failed|rolled_back)"' "$state_file" 2>/dev/null; then
      write_status "$state_file" "$job_id" "failed" 100 "Cloud update failed before a safe final state was confirmed." "$version" || true
    fi
    exit "$exit_code"
  }
  local required_command
  for required_command in curl tar sha256sum flock sort; do
    command -v "$required_command" >/dev/null 2>&1 \
      || fail_apply_preflight "$state_file" "$job_id" "$version" "Required command is missing: $required_command"
  done
  mkdir -p "$RELEASES_DIR" "$SHARED_DIR" "$STAGING_DIR" \
    || fail_apply_preflight "$state_file" "$job_id" "$version" "Unable to prepare the cloud installation directories."
  exec 9>"$INSTALL_ROOT/.update-operation.lock"
  flock -n 9 \
    || fail_apply_preflight "$state_file" "$job_id" "$version" "Another installation or update is already running."
  # Only the process that owns the update lock may remove the maintenance
  # marker or publish terminal update state. A competing invocation exits
  # above without disturbing the active maintainer.
  trap apply_release_exit EXIT
  persist_installer
  prune_installation_artifacts

  local job_dir="$STAGING_DIR/$job_id" archive="$STAGING_DIR/$job_id/$asset_name"
  local extract_dir="$job_dir/extract" release_dir="$RELEASES_DIR/$version"
  local previous_target="" previous_version="" previous_process_version="" previous_ready_version="" runtime_was_running=0
  local previous_guard_valid=0 reinstall_current=0 runtime_stopped=0 first_managed_install=0
  [[ -f "$INSTALL_ROOT/.cloud-install-root" ]] || first_managed_install=1
  previous_process_version="$(current_process_version)"
  previous_ready_version="$(current_health_version)"
  [[ -n "$previous_process_version" ]] && runtime_was_running=1
  if [[ -L "$CURRENT_LINK" ]]; then
    previous_target="$(readlink -f "$CURRENT_LINK" || true)"
  fi
  if [[ -n "$previous_target" && -d "$previous_target" ]]; then
    previous_version="$(release_identity_version "$previous_target" || true)"
    if [[ -n "$previous_version" ]] && release_guard_is_valid "$previous_target"; then
      previous_guard_valid=1
    fi
  fi
  if [[ -n "$previous_version" ]] && version_is_newer "$previous_version" "$version"; then
    write_status "$state_file" "$job_id" "failed" 100 "Refusing to replace the installed release with an older version." "$version"
    return 1
  fi
  if [[ -n "$previous_target" && "$previous_target" == "$release_dir" ]]; then
    if [[ "$previous_ready_version" == "$version" && "$previous_version" == "$version" && "$previous_guard_valid" == "1" ]]; then
      install_guard_from_release "$previous_target"
      if ! configure_supervisor; then
        [[ "$first_managed_install" != "1" ]] || deactivate_failed_first_release
        write_status "$state_file" "$job_id" "failed" 100 "The release is healthy, but its supervisor could not be configured." "$version"
        return 1
      fi
      if ! finalize_supervisor; then
        [[ "$first_managed_install" != "1" ]] || deactivate_failed_first_release
        write_status "$state_file" "$job_id" "failed" 100 "The release is healthy, but its supervisor could not be enabled." "$version"
        return 1
      fi
      write_status "$state_file" "$job_id" "completed" 100 "This release is already active." "$version"
      return 0
    fi
    if [[ "$previous_version" == "$version" && "$previous_guard_valid" == "1" ]]; then
      if ! configure_supervisor; then
        [[ "$first_managed_install" != "1" ]] || deactivate_failed_first_release
        write_status "$state_file" "$job_id" "failed" 100 "The installed release is valid, but its supervisor could not be configured." "$version"
        return 1
      fi
      begin_maintenance
      install_guard_from_release "$previous_target"
      write_status "$state_file" "$job_id" "restarting" 88 "Restarting the verified installed release." "$version"
      stop_current_runtime
      end_maintenance
      start_runtime "$runtime_was_running"
      if wait_for_version "$version" 80; then
        if ! finalize_supervisor; then
          [[ "$first_managed_install" != "1" ]] || deactivate_failed_first_release
          write_status "$state_file" "$job_id" "failed" 100 "The release is healthy, but its supervisor could not be enabled." "$version"
          return 1
        fi
        write_status "$state_file" "$job_id" "completed" 100 "The installed release was verified and restarted successfully." "$version"
        prune_installation_artifacts
        return 0
      fi
      [[ "$first_managed_install" != "1" ]] || deactivate_failed_first_release
      write_status "$state_file" "$job_id" "failed" 100 "The installed release is valid but did not become healthy after restart." "$version"
      return 1
    fi
    # A same-version directory with an invalid executable or guard is not a
    # usable release. Install the signed replacement into a distinct immutable
    # directory so a crash can never leave the current symlink half-replaced;
    # never treat the invalid directory as a rollback candidate.
    reinstall_current=1
    release_dir="$RELEASES_DIR/${version}-repair-${job_id}"
    previous_target="$(readlink -f "$PREVIOUS_LINK" 2>/dev/null || true)"
    previous_version=""
    previous_guard_valid=0
    if [[ -n "$previous_target" && -d "$previous_target" ]]; then
      previous_version="$(release_identity_version "$previous_target" || true)"
      if [[ -n "$previous_version" ]] && release_guard_is_valid "$previous_target"; then
        previous_guard_valid=1
      fi
    fi
  fi

  rm -rf "$job_dir"
  mkdir -p "$extract_dir"
  write_status "$state_file" "$job_id" "downloading" 18 "Downloading release package." "$version"
  curl --fail --location --retry 3 --retry-delay 1 --retry-max-time 1200 --connect-timeout 10 --max-time 600 -o "$archive" "$asset_url"
  if [[ -n "$expected_sha" ]]; then
    [[ "$(sha256sum "$archive" | awk '{print $1}')" == "${expected_sha,,}" ]] || die "Release archive SHA-256 digest mismatch."
  fi
  write_status "$state_file" "$job_id" "verifying" 55 "Verifying release package." "$version"
  validate_archive "$archive"
  tar -xzf "$archive" --no-same-owner --no-same-permissions -C "$extract_dir"
  verify_packaged_executable "$extract_dir" "$version"
  release_guard_is_valid "$extract_dir" || die "Cloud guard is missing or invalid in the release archive."

  rm -rf "${release_dir}.new"
  mv "$extract_dir" "${release_dir}.new"
  configure_supervisor
  begin_maintenance
  if [[ "$reinstall_current" == "1" ]]; then
    stop_current_runtime
    runtime_stopped=1
  fi
  rm -rf "$release_dir"
  mv "${release_dir}.new" "$release_dir"
  if [[ ! -f "$SHARED_DIR/config.toml" && -f "$release_dir/config.toml" ]]; then
    cp "$release_dir/config.toml" "$SHARED_DIR/config.toml"
    chmod 0600 "$SHARED_DIR/config.toml"
  fi
  install_guard_from_release "$release_dir"
  if [[ -n "$previous_target" && -d "$previous_target" ]]; then
    ln -sfn "$previous_target" "${PREVIOUS_LINK}.new"
    mv -Tf "${PREVIOUS_LINK}.new" "$PREVIOUS_LINK"
  fi
  ln -sfn "$release_dir" "${CURRENT_LINK}.new"
  mv -Tf "${CURRENT_LINK}.new" "$CURRENT_LINK"
  write_status "$state_file" "$job_id" "restarting" 88 "Switching version and restarting service." "$version"

  if [[ "$runtime_stopped" != "1" ]]; then
    stop_current_runtime
  fi
  end_maintenance
  start_runtime "$runtime_was_running"
  if wait_for_version "$version" 80; then
    if ! finalize_supervisor; then
      [[ "$first_managed_install" != "1" ]] || deactivate_failed_first_release
      write_status "$state_file" "$job_id" "failed" 100 "The release is healthy, but its supervisor could not be enabled." "$version"
      return 1
    fi
    write_status "$state_file" "$job_id" "completed" 100 "Update completed." "$version"
    rm -rf "$job_dir"
    prune_installation_artifacts
    return 0
  fi

  if [[ -n "$previous_target" && -d "$previous_target" && -n "$previous_version" && "$previous_guard_valid" == "1" ]]; then
    begin_maintenance
    install_guard_from_release "$previous_target"
    stop_current_runtime
    ln -sfn "$previous_target" "${CURRENT_LINK}.rollback"
    mv -Tf "${CURRENT_LINK}.rollback" "$CURRENT_LINK"
    end_maintenance
    start_runtime 1
    if wait_for_version "$previous_version" 80; then
      if ! finalize_supervisor; then
        write_status "$state_file" "$job_id" "failed" 100 "The previous release recovered, but its supervisor could not be enabled." "$version"
        return 1
      fi
      write_status "$state_file" "$job_id" "rolled_back" 100 "New version failed readiness checks; previous version was verified and restored." "$version"
      prune_installation_artifacts
      return 1
    fi
    write_status "$state_file" "$job_id" "failed" 100 "The new version failed and the previous version could not be restored safely." "$version"
    return 1
  fi
  [[ "$first_managed_install" != "1" ]] || deactivate_failed_first_release
  write_status "$state_file" "$job_id" "failed" 100 "New version failed readiness checks and no verified previous version was available." "$version"
  return 1
}

resolve_latest_release() {
  need curl
  local response tag url
  response="$(curl --fail --silent --show-error --location --connect-timeout 10 --max-time 30 \
    -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28' \
    "https://api.github.com/repos/${RELEASE_REPO}/releases/latest")"
  # GitHub may return either pretty-printed or compact single-line JSON.
  # Extract individual key/value tokens instead of assuming one field per line.
  tag="$(printf '%s\n' "$response" \
    | grep -oE '"tag_name"[[:space:]]*:[[:space:]]*"[^"]+"' \
    | head -n 1 \
    | sed 's/^[^:]*:[[:space:]]*"\([^"]*\)"$/\1/' \
    || true)"
  url="$(printf '%s\n' "$response" \
    | grep -oE '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]+"' \
    | sed 's/^[^:]*:[[:space:]]*"\([^"]*\)"$/\1/' \
    | grep -F "/${CLOUD_ARCHIVE}" \
    | head -n 1 \
    || true)"
  [[ -n "$tag" && -n "$url" ]] || die "Latest GitHub release or fixed cloud asset was not found."
  tag="${tag#v}"; tag="${tag#V}"
  [[ "$tag" =~ ^[0-9]+(\.[0-9]+)+$ ]] || die "Latest GitHub release tag is not a supported version."
  printf '%s\n%s\n' "$tag" "$url"
}

install_or_update() {
  local resolved version url job_id
  mkdir -p "$SHARED_DIR"
  resolved="$(resolve_latest_release)"
  version="$(printf '%s\n' "$resolved" | sed -n '1p')"
  url="$(printf '%s\n' "$resolved" | sed -n '2p')"
  job_id="manual-$(date -u +%Y%m%d%H%M%S)-$$"
  apply_release --job-id "$job_id" --state-file "$DEFAULT_STATE_FILE" --version "$version" --asset-url "$url" --asset-name "$CLOUD_ARCHIVE"
  # A directory becomes a managed installation only after the downloaded
  # release has passed readiness checks.  Until then a one-time legacy
  # migration can be retried with the same command and source directory.
  mark_install_root
  printf '%s %s is installed in %s\n' "$APP_NAME" "$version" "$INSTALL_ROOT"
}

case "${1:-install}" in
  apply-release) shift; apply_release "$@" ;;
  install|update) install_or_update ;;
  status) [[ -f "$DEFAULT_STATE_FILE" ]] && cat "$DEFAULT_STATE_FILE" || printf '{"status":"not_found"}\n' ;;
  *) die "Usage: install-cloud.sh [--install-dir PATH] [--supervisor MODE] [install|update|status|apply-release]" ;;
esac
