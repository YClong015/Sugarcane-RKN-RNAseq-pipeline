#!/usr/bin/env bash
set -euo pipefail

if [[ -f config/config.env ]]; then
  echo "[ERROR] config/config.env already exists." >&2
  exit 1
fi

cp config/config.env.example config/config.env
echo "[INFO] Created config/config.env"
