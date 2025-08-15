process DEMUX_CORE {
    tag "$params.pool_ID"
    publishDir path: "${params.outdir}/demuxed_fastq", mode: 'copy', pattern: "*seqWell*"
    publishDir path: "${params.outdir}/other/ME_tagged_fastq", mode: 'copy', pattern: '*tag*'

    input:
    path(fq)
    path(barcodes)

    output:
    path("*.ME.tagged.fastq.gz")
    path("{*seqWell,unknown}.fastq.gz"),     emit: fq
    path("*.cutadapt_report.txt")
    

    script:
    """
    # Step 1: Demultiplex
    cutadapt --no-indels -j $task.cpus \
        --minimum-length ${params.length_filter} \
        -g file:${barcodes} \
        -O 17 \
        -e ${params.error_rate} \
        -o {name}_step1.fastq.gz \
        ${fq}

    # Step 2: Adapter trim (single-end)
    # Assuming only one demuxed file per barcode
    for f in *_step1.fastq.gz; do
        base=\$(basename \$f _step1.fastq.gz)
        cutadapt \
            -g AGATGTGTATAAGAGACAG \
            --minimum-length 150 \
            --overlap 10 \
            -o \${base}.step2.fastq.gz \
            \$f
    done

    # Step 3: Tag ME detection
    for f in *.step2.fastq.gz; do
        base=\$(basename \$f .step2.fastq.gz)
        cutadapt \
            -b AGATGTGTATAAGAGACAG \
            -b CTGTCTCTTATACACATCT \
            -e 0 \
            -O 19 \
            --action=none \
            --report=minimal \
            --untrimmed-output \${base}.seqWell.fastq.gz \
            -o \${base}.ME.tagged.fastq.gz \
            \$f > \${base}.cutadapt_report.txt
    done
    rm *step*.fastq.gz
    mv unknown.seqWell.fastq.gz unknown.fastq.gz
    """
}
