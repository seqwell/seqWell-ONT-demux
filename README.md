# seqWell-ONT-demux

barcodeID,Index well,Reference

[![Nextflow Workflow Tests](https://github.com/seqwell/seqWell-ONT-demux/actions/workflows/nextflow-ci.yml/badge.svg?branch=main)](https://github.com/seqwell/seqWell-ONT-demux/actions/workflows/nextflow-ci.yml?query=branch%3Amain)
[![Nextflow](https://img.shields.io/badge/Nextflow%20DSL2-%E2%89%A523.04.0-blue.svg)](https://www.nextflow.io/)



This is a Nextflow pipeline for demultiplexing ONT FASTQ files using seqWell kit. The pipeline processes multiple FASTQ files by first merging them, then performing demultiplexing, and finally generating summary statistics. The pipeline workflow is streamlined for efficient processing of multiplexed ONT sequencing data.

## Pipeline Overview

The pipeline starts with multiple FASTQ.gz files and follows these key steps:

1. **MERGE_FASTQ**: Collects and merges all input FASTQ files into a single consolidated file for processing
2. **DEMUX_CORE**: Performs the core demultiplexing process using provided barcode sequences to separate reads by sample
3. **DEMUX_SUMMARIZE**: Generates comprehensive summary statistics and reports from the demultiplexing results

The final output includes demultiplexed FASTQ files organized by sample and detailed summary reports showing demultiplexing efficiency and read distribution.

## Dependencies

This pipeline requires installation of Nextflow. It also requires installation of either a containerization platform such as Docker or a package manager such as conda/mamba.

### Docker Containers
All docker containers used in this pipeline should be publicly available. The specific containers will depend on the tools used in your modules (not specified in the main workflow file).

### Conda Environment
A conda environment can be defined in `environment-pipeline.yml` and will be built automatically if the pipeline is run with `-profile conda`.

## How to run the pipeline

### Required Parameters

The required parameters are `input`, `barcodes`, and `output`.

#### input
`input` is the path to a directory containing FASTQ.gz files to be demultiplexed. The pipeline will automatically discover all `*.fastq.gz` files in this directory.

```
--input "/path/to/fastq/directory"
```

#### barcodes  
`barcodes` is the path to a barcode file (likely in FASTA format) containing the barcode sequences used for demultiplexing.

```
--barcodes "/path/to/barcode/file.fasta"
```

#### output
The output directory path where results will be saved. This can be a local absolute path or an AWS S3 URI. If using an AWS S3 URI, please ensure your security credentials are configured appropriately.

```
--output "/path/to/output/directory"
```

### Profiles

Several profiles are available and can be selected with the `-profile` option at the command line:

- `apptainer`
- `aws`
- `conda` 
- `docker`
- `singularity`

### Example Command

A minimal execution might look like:

```bash
nextflow run \
    -profile docker \
    main.nf \
    --input "${PWD}/path/to/fastq/directory" \
    --barcodes "${PWD}/path/to/barcodes.fasta" \
    --output "${PWD}/path/to/output"
```

## Running Test Data

### With Docker
The pipeline can be run using test data with:

```bash
nextflow run \
    -profile docker \
    main.nf \
    -c nextflow.config \
    --input "${PWD}/test_data/fastq" \
    --barcodes "${PWD}/test_data/barcodes.fasta" \
    --output "${PWD}/test_output" \
    -with-report \
    -with-trace \
    -resume
```

### With Conda
```bash
nextflow run \
    -profile conda \
    main.nf \
    -c nextflow.config \
    --input "${PWD}/test_data/fastq" \
    --barcodes "${PWD}/test_data/barcodes.fasta" \
    --output "${PWD}/test_output" \
    -with-report \
    -with-trace \
    -resume
```

## Expected Outputs

```
test_output/
├── merged_fastq/
│   └── merged_reads.fastq.gz                    # Consolidated FASTQ file from all input files
├── demultiplexed/
│   ├── sample_01.fastq.gz                       # Demultiplexed reads for sample 01
│   ├── sample_02.fastq.gz                       # Demultiplexed reads for sample 02
│   ├── ...
│   └── unassigned.fastq.gz                      # Reads that could not be assigned to any sample
├── summary/
│   ├── demux_summary_report.csv                 # Summary of demultiplexing results
│   ├── barcode_counts.txt                       # Count of reads assigned to each barcode
│   └── demux_statistics.html                    # Detailed HTML report with statistics
└── logs/
    ├── execution_report_[DATE-TIME-STAMP].html  # Nextflow execution report
    ├── execution_timeline_[DATE-TIME-STAMP].html # Nextflow execution timeline
    ├── execution_trace_[DATE-TIME-STAMP].txt    # Nextflow execution trace
    └── pipeline_dag_[DATE-TIME-STAMP].html      # Nextflow pipeline DAG
```

## Module Dependencies

This pipeline relies on three custom modules that must be present in the `modules/` directory:

- `modules/demux_core.nf` - Contains the core demultiplexing logic
- `modules/demux_summarize.nf` - Generates summary statistics and reports  
- `modules/merge_fastq.nf` - Handles merging of input FASTQ files

## Configuration

Additional pipeline configuration can be specified in `nextflow.config`. This may include:

- Resource allocation (CPU, memory)
- Container specifications
- Profile-specific settings
- Parameter defaults

## Troubleshooting

- Ensure all input FASTQ files are properly gzipped with `.fastq.gz` extension
- Verify barcode file format is compatible with the demultiplexing tools used in `DEMUX_CORE`
- Check that sufficient disk space is available for merged FASTQ files and outputs
- For AWS S3 usage, confirm AWS credentials and permissions are properly configured






