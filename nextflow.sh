#!/bin/bash

input=test/data/fastq_pass
outdir=20250811_demux
pool_ID=20250811


nextflow run \
main.nf \
--input $input \
--outdir $outdir \
--pool_ID $pool_ID \
-resume -bg
