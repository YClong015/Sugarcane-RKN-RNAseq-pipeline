#!/usr/bin/env bash
set -euo pipefail

die() { echo "[ERROR] $*" >&2; exit 1; }

note() { echo "[INFO] $*"; }

load_cfg() {
  local cfg="${1:-config/config.env}"
  [[ -f "$cfg" ]] || die "Missing config: $cfg"
  # shellcheck disable=SC1090
  source "$cfg"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

ensure_dir() {
  mkdir -p "$@"
}
