version 1.0

import "../types.wdl"

task sequenceToFastqRna {
  input {
    File? bam
    File? fastq1
    File? fastq2
    Boolean unzip_fastqs = false
  }

  Int space_needed_gb = 10 + ceil(2*size([bam, fastq1, fastq2], "GB"))
  runtime {
    memory: "16GB"
    bootDiskSizeGb: 25
    docker: "mgibio/rnaseq:1.0.0"
    disks: "local-disk ~{space_needed_gb} SSD"
  }

  String outdir = "outdir"
  command <<<
    set -o pipefail
    set -o errexit
    set -o nounset

    UNZIP=~{unzip_fastqs}
    OUTDIR=~{outdir}
    BAM=~{if defined(bam) then bam else ""}
    FASTQ1=~{if defined(fastq1) then fastq1 else ""}
    FASTQ2=~{if defined(fastq2) then fastq2 else ""}
    MODE=~{if defined(bam) then "bam" else "fastq"}

    mkdir -p $OUTDIR

    if [[ "$MODE" == 'fastq' ]]; then #must be fastq input
        if $UNZIP; then
            if gzip -t $FASTQ1 2> /dev/null; then
                gunzip -c $FASTQ1 > $OUTDIR/read1.fastq
            else
                cp $FASTQ1 $OUTDIR/read1.fastq
            fi

            if gzip -t $FASTQ2 2> /dev/null; then
                gunzip -c $FASTQ2 > $OUTDIR/read2.fastq
            else
                cp $FASTQ2 $OUTDIR/read2.fastq
            fi
        else
            if gzip -t $FASTQ1 2> /dev/null; then
                cp $FASTQ1 $OUTDIR/read1.fastq.gz
            else
                cp $FASTQ1 $OUTDIR/read1.fastq
            fi

            if gzip -t $FASTQ2 2> /dev/null; then
                cp $FASTQ2 $OUTDIR/read2.fastq.gz
            else
                cp $FASTQ2 $OUTDIR/read2.fastq
            fi
        fi

    else # then
        ##run samtofastq here, dumping to the same filenames
        ## input file is $BAM
        /usr/bin/java -Xmx4g -jar /opt/picard/picard.jar SamToFastq I="$BAM" INCLUDE_NON_PF_READS=true F=$OUTDIR/read1.fastq F2=$OUTDIR/read2.fastq VALIDATION_STRINGENCY=SILENT
    fi
  >>>

  output {
    File read1_fastq = "~{outdir}/read1.fastq"
    File read2_fastq = "~{outdir}/read2.fastq"
  }
}
