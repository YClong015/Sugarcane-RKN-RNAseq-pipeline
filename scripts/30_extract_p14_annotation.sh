#!/usr/bin/env bash
set -euo pipefail
source scripts/utils.sh
load_cfg

need_cmd zcat
need_cmd awk

[[ -f "$P14_ANNOT_INFO_GZ" ]] || die "Missing: $P14_ANNOT_INFO_GZ"

zcat "$P14_ANNOT_INFO_GZ"   | awk -F'	' 'BEGIN{OFS="	"}
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
    }'   > "$P14_ANNOT_TSV"

head "$P14_ANNOT_TSV" || true
note "P14 annotation written: $P14_ANNOT_TSV"
