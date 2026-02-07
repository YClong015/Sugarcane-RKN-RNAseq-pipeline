#!/usr/bin/env bash
set -euo pipefail
source scripts/utils.sh
load_cfg

ensure_dir   "$RAW_DIR" "$NAMED_DIR" "$MERGED_DIR" "$QC_RAW_DIR"   "$CLEAN_DIR" "$QC_CLEAN_DIR" "$SMUT_DIR" "$REF_DIR"   "$SALMON_DIR" "$DESEQ_DIR"

note "Directories created under: $BASE_DIR"
