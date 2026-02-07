#!/usr/bin/env bash
set -euo pipefail
source scripts/utils.sh
load_cfg

need_cmd awk

[[ -f "$R570_GFF3" ]] || die "Missing: $R570_GFF3"

awk -F'	' '
  $3=="mRNA" || $3=="transcript" {
    id=""; parent="";
    n=split($9,a,";");
    for(i=1;i<=n;i++){
      if(a[i] ~ /^ID=/){sub(/^ID=/,"",a[i]); id=a[i]}
      if(a[i] ~ /^Parent=/){sub(/^Parent=/,"",a[i]); parent=a[i]}
    }
    if(id!="" && parent!=""){print id"	"parent}
  }
' "$R570_GFF3" | sort -u > "$TX2GENE_TSV"

head "$TX2GENE_TSV" || true
note "tx2gene written: $TX2GENE_TSV"
