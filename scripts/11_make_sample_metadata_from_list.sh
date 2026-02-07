#!/usr/bin/env bash
set -euo pipefail
source scripts/utils.sh
load_cfg

[[ -f "$SAMPLES_RKN_ONLY_TXT" ]] || die "Missing: $SAMPLES_RKN_ONLY_TXT"

OUT_CSV="${DESEQ_DIR}/sample_metadata.csv"
echo "sample,genotype,time,treatment,rep" > "$OUT_CSV"

awk -F'_' 'BEGIN{OFS=","}
{
  rep=$4;
  for(i=5;i<=NF;i++) rep=rep"_"$i;
  print $0,$1,$2,$3,rep
}' "$SAMPLES_RKN_ONLY_TXT" >> "$OUT_CSV"

head "$OUT_CSV" || true
note "Metadata written: $OUT_CSV"
