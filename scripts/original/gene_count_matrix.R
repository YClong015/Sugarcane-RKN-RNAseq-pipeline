BiocManager::install("tximport")
library(tximport)

meta <- read.csv("/QRISdata/Q9062/08_deseq2/sample_metadata.csv",
                 stringsAsFactors = FALSE)

files <- file.path("/QRISdata/Q9062/07_salmon/quants", meta$sample, "quant.sf")
names(files) <- meta$sample

if (!all(file.exists(files))) {
  stop("Missing quant.sf for some samples")
}

tx2gene <- read.delim("/QRISdata/Q9062/06_ref/tx2gene.tsv",
                      header = FALSE,
                      stringsAsFactors = FALSE)
colnames(tx2gene) <- c("TXNAME", "GENEID")

txi <- tximport(files,
                type = "salmon",
                tx2gene = tx2gene,
                ignoreTxVersion = FALSE)

counts <- as.data.frame(txi$counts)
counts <- counts[, meta$sample, drop = FALSE]

out <- data.frame(gene_id = rownames(counts),
                  counts,
                  check.names = FALSE)

write.csv(out,
          file = "/QRISdata/Q9062/08_deseq2/gene_counts_matrix.csv",
          row.names = FALSE)
