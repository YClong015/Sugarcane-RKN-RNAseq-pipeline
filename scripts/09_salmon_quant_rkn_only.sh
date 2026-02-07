#!/usr/bin/env bash
set -euo pipefail
source scripts/utils.sh
load_cfg

need_cmd salmon

READS_DIR="${SMUT_DIR}/clean"
OUT_DIR="${SALMON_DIR}/quants"
ensure_dir "$OUT_DIR"

[[ -f "$SAMPLES_RKN_ONLY_TXT" ]] || die "Missing: $SAMPLES_RKN_ONLY_TXT"

while read -r s; do
  ensure_dir "$OUT_DIR/$s"

  salmon quant     -i "$SALMON_INDEX_DIR"     -l A     -1 "$READS_DIR/${s}_R1.fastq.gz"     -2 "$READS_DIR/${s}_R2.fastq.gz"     -p "$THREADS"     --validateMappings     -o "$OUT_DIR/$s"
done < "$SAMPLES_RKN_ONLY_TXT"

note "Salmon quant finished: $OUT_DIR"
