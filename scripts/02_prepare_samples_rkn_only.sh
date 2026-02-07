#!/usr/bin/env bash
set -euo pipefail
source scripts/utils.sh
load_cfg

# Copy template if missing
if [[ ! -f "$SAMPLES_RKN_ONLY_TXT" ]]; then
  ensure_dir "$DESEQ_DIR"
  cp metadata/samples_rkn_only.txt "$SAMPLES_RKN_ONLY_TXT"
  note "Created: $SAMPLES_RKN_ONLY_TXT"
  note "Edit it, then rerun this script."
  exit 0
fi

# Enforce: drop RLN lines (including SES208_12w_RLN_3)
tmp="${SAMPLES_RKN_ONLY_TXT}.tmp"
grep -v -E 'RLN|SES208_12w_RLN_3' "$SAMPLES_RKN_ONLY_TXT"   | grep -v -E '^\s*#'   | awk 'NF>0{print $1}'   > "$tmp"

mv "$tmp" "$SAMPLES_RKN_ONLY_TXT"

if grep -q -E 'RLN|SES208_12w_RLN_3' "$SAMPLES_RKN_ONLY_TXT"; then
  die "RLN still present in $SAMPLES_RKN_ONLY_TXT"
fi

note "Sanitized: $SAMPLES_RKN_ONLY_TXT"
wc -l "$SAMPLES_RKN_ONLY_TXT" || true
