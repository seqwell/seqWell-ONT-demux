#!/usr/bin/env nextflow

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
    
    demuxed_fq_ch = DEMUX_CORE.out.fq
                  .flatten()
                  .map { fq -> tuple(fq.baseName.replace(".fastq",""), fq) }
                  
    
    // Read in the demux summary report and create individual valid ID tuples, only do nanostat on those apprered in the report
    valid_ids_ch = DEMUX_SUMMARIZE.out
        .map { report ->
           def ids = []
           report.eachLine { line ->
               if (line.startsWith("BC_")) {
                   def id = line.split(",")[0].trim()
                   ids << id
               }
               if (line.startsWith("unknown")) {
                   ids << "unknown"
               }
           }
           return ids
        }
        .flatten()  
        .map { id -> tuple(id, true) }  
    
    //valid_ids_ch.view { "Valid ID tuple: $it" }
    
    
    filtered_fq_ch = demuxed_fq_ch
        .join(valid_ids_ch, by: 0)  
        .map { sample_id, fastq_file, flag -> tuple(sample_id, fastq_file) }
    
    //filtered_fq_ch.view { "Filtered: $it" }
    
    READ_LENGTH (filtered_fq_ch)
    NANOSTAT(filtered_fq_ch)
    MULTIQC(NANOSTAT.out.collect())
}