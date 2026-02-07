#!/usr/bin/env bash
set -euo pipefail
source scripts/utils.sh
load_cfg

need_cmd fastqc
need_cmd multiqc

ensure_dir "$QC_CLEAN_DIR"

fastqc -t "$THREADS" -o "$QC_CLEAN_DIR"   "${CLEAN_DIR}"/*_R1.fastq.gz   "${CLEAN_DIR}"/*_R2.fastq.gz

multiqc "$QC_CLEAN_DIR" -o "$QC_CLEAN_DIR"
note "Clean QC done: $QC_CLEAN_DIR"
