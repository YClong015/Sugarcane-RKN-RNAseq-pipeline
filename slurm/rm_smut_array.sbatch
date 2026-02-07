#!/bin/bash --login
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --partition=general
#SBATCH --job-name=rm_smut
#SBATCH --time=24:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=8
#SBATCH --output=slurm_logs/%A_%a.out
#SBATCH --error=slurm_logs/%A_%a.err

set -euo pipefail

source scripts/utils.sh
load_cfg

module load bowtie2 2>/dev/null || true
need_cmd bowtie2

ensure_dir "${SMUT_DIR}/log" "${SMUT_DIR}/clean" "slurm_logs"

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES_RKN_ONLY_TXT")

R1="${CLEAN_DIR}/${SAMPLE}_R1.fastq.gz"
R2="${CLEAN_DIR}/${SAMPLE}_R2.fastq.gz"

[[ -f "$R1" ]] || die "Missing: $R1"
[[ -f "$R2" ]] || die "Missing: $R2"

IDX="$BOWTIE2_INDEX_PREFIX"
OUT="${SMUT_DIR}/clean/${SAMPLE}_R%.fastq.gz"

bowtie2   -x "$IDX"   -1 "$R1"   -2 "$R2"   --very-sensitive   -p "${SLURM_CPUS_PER_TASK}"   --un-conc-gz "$OUT"   -S /dev/null   2> "${SMUT_DIR}/log/${SAMPLE}.bowtie2.log"
