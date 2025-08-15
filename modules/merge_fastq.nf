process MERGE_FASTQ {

    tag "${params.pool_ID}"
    
    publishDir path: "${params.outdir}/merged_fq", mode: 'copy'
    
    input:
    path(fqs)

    output:
    path("${params.pool_ID}_ONT.fastq.gz"), emit: fq1
  

    script:
    """
    cat ${fqs.join(' ')}  > ${params.pool_ID}_ONT.fastq.gz
    """
}
