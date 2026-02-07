#!/usr/bin/env bash
set -euo pipefail
source scripts/utils.sh
load_cfg

need_cmd bowtie2-build

[[ -f "$SMUT_GENOME_FA" ]] || die "Missing: $SMUT_GENOME_FA"
ensure_dir "${SMUT_DIR}/index"

bowtie2-build "$SMUT_GENOME_FA" "$BOWTIE2_INDEX_PREFIX"
note "Bowtie2 index built: $BOWTIE2_INDEX_PREFIX"
