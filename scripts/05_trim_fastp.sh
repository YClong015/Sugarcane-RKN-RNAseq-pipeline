#!/usr/bin/env bash
set -euo pipefail
source scripts/utils.sh
load_cfg

need_cmd fastp

[[ -f "$SAMPLES_RKN_ONLY_TXT" ]] || die "Missing: $SAMPLES_RKN_ONLY_TXT"
ensure_dir "$CLEAN_DIR"

while read -r s; do
  note "fastp: $s"

  fastp     --in1 "${MERGED_DIR}/${s}_R1.fastq.gz"     --in2 "${MERGED_DIR}/${s}_R2.fastq.gz"     --out1 "${CLEAN_DIR}/${s}_R1.fastq.gz"     --out2 "${CLEAN_DIR}/${s}_R2.fastq.gz"     --detect_adapter_for_pe     --trim_front1 13     --trim_front2 13     --cut_tail     --cut_window_size 4     --cut_mean_quality 29     --length_required 50     --thread "$THREADS"     --html "${CLEAN_DIR}/${s}.fastp.html"     --json "${CLEAN_DIR}/${s}.fastp.json"
done < "$SAMPLES_RKN_ONLY_TXT"

note "fastp finished: $CLEAN_DIR"
