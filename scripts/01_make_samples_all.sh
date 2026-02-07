#!/usr/bin/env bash
set -euo pipefail
source scripts/utils.sh
load_cfg

# This mirrors your original logic.
# If your flowcell token differs, pass it as an argument.
FLOWCELL_TOKEN="${1:-_HLCH2DRXY_}"

ensure_dir "$MERGED_DIR"

ls "${NAMED_DIR}"/*_L001_R1.fastq.gz   | sed "s/${FLOWCELL_TOKEN}.*//"   | sed "s#${NAMED_DIR}/##"   | sort -u > "$SAMPLES_ALL_TXT"

note "Wrote: $SAMPLES_ALL_TXT"
wc -l "$SAMPLES_ALL_TXT" || true
