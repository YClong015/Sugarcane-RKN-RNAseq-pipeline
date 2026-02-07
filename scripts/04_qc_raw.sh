#!/usr/bin/env bash
set -euo pipefail
source scripts/utils.sh
load_cfg

need_cmd fastqc
need_cmd multiqc

ensure_dir "$QC_RAW_DIR"

fastqc -t "$THREADS" -o "$QC_RAW_DIR"   "${MERGED_DIR}"/*_R1.fastq.gz   "${MERGED_DIR}"/*_R2.fastq.gz

multiqc "$QC_RAW_DIR" -o "$QC_RAW_DIR"
note "Raw QC done: $QC_RAW_DIR"
