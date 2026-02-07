#!/usr/bin/env bash
set -euo pipefail
source scripts/utils.sh
load_cfg

need_cmd zcat
need_cmd pigz

[[ -f "$SAMPLES_RKN_ONLY_TXT" ]] || die "Missing: $SAMPLES_RKN_ONLY_TXT"

ensure_dir "$MERGED_DIR"

while read -r s; do
  note "Merging lanes: $s"

  zcat "${NAMED_DIR}/${s}"_*_L00?_R1.fastq.gz     | pigz -p "$THREADS" > "${MERGED_DIR}/${s}_R1.fastq.gz"

  zcat "${NAMED_DIR}/${s}"_*_L00?_R2.fastq.gz     | pigz -p "$THREADS" > "${MERGED_DIR}/${s}_R2.fastq.gz"
done < "$SAMPLES_RKN_ONLY_TXT"

note "Merging finished: $MERGED_DIR"
