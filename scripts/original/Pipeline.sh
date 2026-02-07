# 0. Create directories for RNA-seq data processing pipeline
mkdir -p 00_raw 00_named 01_merged 02_qc_raw 03_clean 04_qc_clean 05_smut
mkdir -p 06_trinity 07_quant 08_matrix 09_DE

# 1. Check MD5 checksums for raw data files
md5sum -c checksums.md5 | tee 00_raw/md5_check.log
# 1b. Create symbolic links with simplified names for raw data files
for f in *_R1.fastq.gz *_R2.fastq.gz; do
  case "$f" in
    A[0-9]*_*) ;;
    *) ln -sf "../$f" "00_named/$f" ;;
  esac
done
# Specific renaming for certain files
ln -sf ../A343102_* 00_named/Q208_7d_C_2_*
ln -sf ../A343103_* 00_named/Q208_7d_C_3_*
ln -sf ../A343104_* 00_named/Q208_7d_C_4_*
ln -sf ../A342101_* 00_named/Q208_7d_RKN_1_*
ln -sf ../A342102_* 00_named/Q208_7d_RKN_2_*
ln -sf ../A342103_* 00_named/Q208_7d_RKN_3_*
ln -sf ../A342081_* 00_named/SES208_12w_RKN_4_*
ln -sf ../A341081_* 00_named/SES208_12w_RLN_3_*

# find and link specific files
rm -f "Q208_7d_C_2_*" "Q208_7d_C_3_*" "Q208_7d_C_4_*"
rm -f "Q208_7d_RKN_1_*" "Q208_7d_RKN_2_*" "Q208_7d_RKN_3_*"
rm -f "SES208_12w_RKN_4_*" "SES208_12w_RLN_3_*"
# function to create symbolic links
make_links () {
  src="$1"
  dst="$2"
  for f in ../"${src}"_*; do
    b=$(basename "$f")
    ln -sf "$f" "${dst}${b#${src}}"
  done
}
make_links A343102 Q208_7d_C_2
make_links A343103 Q208_7d_C_3
make_links A343104 Q208_7d_C_4
make_links A342101 Q208_7d_RKN_1
make_links A342102 Q208_7d_RKN_2
make_links A342103 Q208_7d_RKN_3
make_links A342081 SES208_12w_RKN_4
make_links A341081 SES208_12w_RLN_3

# 2. Generate a list of unique sample identifiers
ls 00_named/*_L001_R1.fastq.gz \
  | sed 's/_HLCH2DRXY_.*//' \
  | sed 's#00_named/##' \
  | sort -u > 01_merged/samples.txt

# 3. Merge paired-end reads for each sample
while read -r s; do
  zcat 00_named/${s}_HLCH2DRXY_*_L00?_R1.fastq.gz \
    | pigz -p 8 > 01_merged/${s}_R1.fastq.gz

  zcat 00_named/${s}_HLCH2DRXY_*_L00?_R2.fastq.gz \
    | pigz -p 8 > 01_merged/${s}_R2.fastq.gz
done < 01_merged/samples.txt
# Summary of merged files
wc -l 01_merged/samples.txt
ls 01_merged/*_R1.fastq.gz | wc -l
ls 01_merged/*_R2.fastq.gz | wc -l

#  4. Quality control of merged raw reads
cd /QRISdata/Q9062
module load fastqc multiqc 2>/dev/null || true

fastqc -t 8 -o 02_qc_raw 01_merged/*_R1.fastq.gz 01_merged/*_R2.fastq.gz
multiqc 02_qc_raw -o 02_qc_raw

# 5. Quality control of cleaned reads
while read -r s; do
  fastp \
    --in1 "${s}_R1.fastq.gz" \
    --in2 "${s}_R2.fastq.gz" \
    --out1 "../03_clean/${s}_R1.fastq.gz" \
    --out2 "../03_clean/${s}_R2.fastq.gz" \
    --detect_adapter_for_pe \
    --trim_front1 13 \
    --trim_front2 13 \
    --cut_tail \
    --cut_window_size 4 \
    --cut_mean_quality 29 \
    --length_required 50 \
    --thread 8 \
    --html "../03_clean/${s}.fastp.html" \
    --json "../03_clean/${s}.fastp.json"
done < samples.txt

# 6. Quality control of cleaned reads
module load fastqc multiqc 2>/dev/null || true
fastqc -t 8 -o 04_qc_clean 03_clean/*_R1.fastq.gz 03_clean/*_R2.fastq.gz
multiqc 04_qc_clean -o 04_qc_clean

# 7. Remove S. scitamineum reads from cleaned RNA-seq data
# Download S. scitamineum genome and build Bowtie2 index
cd 05_smut/db_src
wget "https://api.ncbi.nlm.nih.gov/datasets/v2/genome/accession/GCA_001010845.1/download?include_annotation_type=GENOME_FASTA&include_annotation_type=GENOME_GFF&include_annotation_type=RNA_FASTA&include_annotation_type=CDS_FASTA&include_annotation_type=PROT_FASTA&include_annotation_type=SEQUENCE_REPORT&hydrated=FULLY_HYDRATED"
unzip "download?include_annotation_type=GENOME_FASTA&include_annotation_type=GENOME_GFF&include_annotation_type=RNA_FASTA&include_annotation_type=CDS_FASTA&include_annotation_type=PROT_FASTA&include_annotation_type=SEQUENCE_REPORT&hydrated=FULLY_HYDRATED"
find ncbi_dataset -name "*_genomic.fna" | head
cp $(find ncbi_dataset -name "*_genomic.fna" | head -n 1) ../smut_genome.fa
# clean up
cd ..
module load bowtie2 2>/dev/null || true
mkdir -p index
bowtie2-build smut_genome.fa index/Ssc39B_genome
# Remove S. scitamineum reads using Bowtie2
mkdir -p 05_smut/log 05_smut/clean
run sbatch job
```
#!/bin/bash --login
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --partition=general
#SBATCH --account=a_nefzger
#SBATCH --job-name=rm_smut
#SBATCH --time=24:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=8
#SBATCH --array=1-25
#SBATCH --output=/QRISdata/Q9062/05_smut/log/%A_%a.out
#SBATCH --error=/QRISdata/Q9062/05_smut/log/%A_%a.err

module load bowtie2 2>/dev/null || true

BASE="/QRISdata/Q9062"
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ${BASE}/01_merged/samples.txt)

R1="${BASE}/03_clean/${SAMPLE}_R1.fastq.gz"
R2="${BASE}/03_clean/${SAMPLE}_R2.fastq.gz"

IDX="${BASE}/05_smut/index/Ssc39B_genome"
OUT="${BASE}/05_smut/clean/${SAMPLE}_R%.fastq.gz"

bowtie2 -x "$IDX" -1 "$R1" -2 "$R2" \
  --very-sensitive -p ${SLURM_CPUS_PER_TASK} \
  --un-conc-gz "$OUT" \
  -S /dev/null \
  2> ${BASE}/05_smut/log/${SAMPLE}.bowtie2.log
```

# 8. Quality control of S. scitamineum removed reads
mkdir -p 05_smut/qc
fastqc -t 8 -o 05_smut/qc 05_smut/clean/*_R1.fastq.gz 05_smut/clean/*_R2.fastq.gz
multiqc 05_smut/qc -o 05_smut/qc
# Quality control of S. scitamineum removed reads
s=Q208_12w_C_1
before=$(zcat 03_clean/${s}_R1.fastq.gz | wc -l)
after=$(zcat 05_smut/clean/${s}_R1.fastq.gz | wc -l)
echo "before_lines=$before after_lines=$after"
echo "before_reads=$((before/4)) after_reads=$((after/4))"
# Summary of alignment rates
grep -H "overall alignment rate" 05_smut/log/*.bowtie2.log \
  | awk '{print $(NF-2), $0}' | sort -n

# 9. Prepare reference for transcript quantification
cd /QRISdata/Q9062
mkdir -p 06_ref 07_salmon/index 07_salmon/quants 08_deseq2
cd 06_ref
# 10. Download S. scitamineum AP85-441 transcriptome and annotation files
# Go find from google ("https://phytozome-next.jgi.doe.gov/")

# 11. Extract CDS sequences from GFF3 and gene fasta
mkdir -p 06_ref/R570_salmon_index
module load salmon 2>/dev/null || true
salmon index \
  -t 06_ref/unpacked/R570_v2.1.transcript.fa \
  -i 06_ref/R570_salmon_index \
  -k 31

# 12. Quantify transcript abundance using Salmon
# Write a array job script will be easy to run
cd /QRISdata/Q9062
READS_DIR="05_smut/clean"
OUT_DIR="07_salmon_R570/quants"
mkdir -p "$OUT_DIR"

while read -r s; do
  mkdir -p "$OUT_DIR/$s"

  salmon quant \
    -i 06_ref/R570_salmon_index \
    -l A \
    -1 "$READS_DIR/${s}_R1.fastq.gz" \
    -2 "$READS_DIR/${s}_R2.fastq.gz" \
    -p 16 \
    --validateMappings \
    -o "$OUT_DIR/$s"
done < 08_deseq2/samples_rkn_only.txt

# 12b. Create tx2gene mapping file for summarizing to gene level
cd /QRISdata/Q9062
awk -F'\t' '
  $3=="mRNA" || $3=="transcript" {
    id=""; parent="";
    n=split($9,a,";");
    for(i=1;i<=n;i++){
      if(a[i] ~ /^ID=/){sub(/^ID=/,"",a[i]); id=a[i]}
      if(a[i] ~ /^Parent=/){sub(/^Parent=/,"",a[i]); parent=a[i]}
    }
    if(id!="" && parent!=""){print id"\t"parent}
  }
' 06_ref/unpacked/R570_v2.1.gff3 \
  | sort -u > 06_ref/tx2gene.tsv

head 06_ref/tx2gene.tsv
wc -l 06_ref/tx2gene.tsv

# 12c. Summarize transcript-level quantifications to gene-level counts
cd /QRISdata/Q9062
awk '
  /^>/{
    sub(/^>/,"",$1)
    tx=$1
    gene=""
    for(i=2;i<=NF;i++){
      if($i ~ /^locus=/){
        gene=$i
        sub(/^locus=/,"",gene)
      }
    }
    if(tx!="" && gene!=""){
      print tx "\t" gene
    }
  }
' 06_ref/SofficinarumxspontaneumR570_771_v2.1.transcript.fa \
  > 06_ref/tx2gene_R570_1os2g.tsv

head 06_ref/tx2gene_R570_1os2g.tsv

# 13. Generate sample list for DESeq2 analysis
ls -1 07_salmon_R570/quants | sort > 08_deseq2/samples.txt
wc -l 08_deseq2/samples.txt
head 08_deseq2/samples.txt
awk -F'_' 'BEGIN{OFS=","; print "sample,genotype,time,treatment,rep"}
{
  rep=$4;
  for(i=5;i<=NF;i++) rep=rep"_"$i;
  print $0,$1,$2,$3,rep
}' 08_deseq2/samples.txt > 08_deseq2/sample_metadata.csv

head 08_deseq2/sample_metadata.csv
# Then run gene_count_matrix.R script in R to generate count matrix

# 14. Differential expression analysis using DESeq2
# Run DESeq2_for_RKN&C.R script in R with appropriate parameters
# to perform differential expression analysis
# and generate results in 08_deseq2/ directory

# 15. Download annotation file for S. scitamineum R570
# also form (https://phytozome-next.jgi.doe.gov/)

# 16. Extract gene annotation information
cd /QRISdata/Q9062/06_ref
zcat SofficinarumxspontaneumR570_771_v2.1.P14.annotation_info.txt.gz \
  | awk -F'\t' 'BEGIN{OFS="\t"}
    NR==1{
      print "gene_id","KO","GO","Pfam","Panther","KOG","ec"
      next
    }
    {
      gene=$2
      pfam=$5
      pan=$6
      ec=$7
      kog=$8
      ko=$9
      go=$10
      if(!(gene in seen)){
        seen[gene]=1
        print gene,ko,go,pfam,pan,kog,ec
      }
    }' \
  > gene_annotation_R570P14.tsv
head gene_annotation_R570P14.tsv

# 17. Annotate DESeq2 results with gene annotation
cd /QRISdata/Q9062/08_deseq2_R570
ANN=/QRISdata/Q9062/06_ref/gene_annotation_R570P14.tsv

for d in *_RKN_vs_C; do
  base=$(basename "$d")
  in_csv="$d/${base}_DESeq2.DE.results.csv"
  out_tsv="$d/${base}_DESeq2.DE.results_with_P14_annotation.tsv"

  python3 - <<PY
import pandas as pd

ann = pd.read_csv("$ANN", sep="\t", dtype=str)
de = pd.read_csv("$in_csv")

m = de.merge(ann, left_on="id", right_on="gene_id", how="left")
m.to_csv("$out_tsv", sep="\t", index=False)

print("$base", "rows:", m.shape[0],
      "annotated_GO:", m["GO"].notna().sum(),
      "annotated_KO:", m["KO"].notna().sum())
PY
done


