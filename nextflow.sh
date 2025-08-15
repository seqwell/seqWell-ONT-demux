#!/bin/bash

outdir=20250811_demux
pool_ID=20250811


/software/nextflow-align/nextflow run \
main.nf \
--outdir $outdir \
--pool_ID $pool_ID \
-resume -bg
