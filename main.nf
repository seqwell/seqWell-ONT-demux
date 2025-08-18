
include { DEMUX_CORE } from './modules/demux_core.nf'
include { DEMUX_SUMMARIZE } from './modules/demux_summarize.nf'
include { MERGE_FASTQ }  from './modules/merge_fastq.nf'
include { NANOSTAT } from './modules/nanostat.nf'
include { MULTIQC } from './modules/multiQC.nf'
include { READ_LENGTH }  from './modules/read_length.nf'



workflow {

    
    Channel
        .fromPath( params.input + "/*.fastq.gz")
        .set { fq_ch }


    Channel
        .fromPath(params.barcodes)
        .set { barcode_ch }

    MERGE_FASTQ( fq_ch.collect() )
    
    DEMUX_CORE( MERGE_FASTQ.out, barcode_ch )
    
    
  
    DEMUX_SUMMARIZE (DEMUX_CORE.out.fq.collect())
    
    DEMUX_CORE.out.fq.view()
    
    demuxed_fq_ch = DEMUX_CORE.out.fq
                  .flatten()
                  .map { fq -> tuple(fq.baseName.replace(".fastq",""), fq) }
    
    READ_LENGTH (demuxed_fq_ch)
    
    NANOSTAT(demuxed_fq_ch)

    MULTIQC(NANOSTAT.out.collect())
    

}
