#!/usr/bin/env bash
set -euo pipefail
source scripts/utils.sh
load_cfg

# If missing, copy the repo template into $DESEQ_DIR and stop.
if [[ ! -f "$SAMPLES_RKN_ONLY_TXT" ]]; then
  tmpl="samples/samples_rkn_only.txt"
  [[ -f "$tmpl" ]] || die "Missing template: $tmpl"
  ensure_dir "$DESEQ_DIR"
  cp "$tmpl" "$SAMPLES_RKN_ONLY_TXT"
  note "Created: $SAMPLES_RKN_ONLY_TXT"
  note "Edit it, then rerun this script."
  exit 0
fi

tmp="${SAMPLES_RKN_ONLY_TXT}.tmp"

# Drop comments + empty lines; keep first column only.
grep -v -E '^[[:space:]]*#' "$SAMPLES_RKN_ONLY_TXT" \
  | awk 'NF > 0 { print $1 }' > "$tmp"

# Optional filtering (configured in config.env).
if [[ -n "${EXCLUDE_SAMPLE_REGEX:-}" ]]; then
  grep -v -E "$EXCLUDE_SAMPLE_REGEX" "$tmp" > "${tmp}.f"
  mv "${tmp}.f" "$tmp"
fi

mv "$tmp" "$SAMPLES_RKN_ONLY_TXT"

note "Sanitized: $SAMPLES_RKN_ONLY_TXT"
wc -l "$SAMPLES_RKN_ONLY_TXT" || true




