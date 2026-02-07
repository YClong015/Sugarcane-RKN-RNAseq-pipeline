#!/usr/bin/env bash
set -euo pipefail
source scripts/utils.sh
load_cfg

need_cmd salmon

[[ -f "$R570_TX_FA" ]] || die "Missing: $R570_TX_FA"
ensure_dir "$SALMON_INDEX_DIR"

salmon index -t "$R570_TX_FA" -i "$SALMON_INDEX_DIR" -k 31
note "Salmon index built: $SALMON_INDEX_DIR"
