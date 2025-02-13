process CONVERTHAPLOTYPESCSVTOTSV {
    time '48h'
    cpus 1
    memory '6 GB'
    label 'process_high'

  input:
    path(infile)
    path(infile_yaml)
  output:
    path("haplotypes.tsv"), emit: haplotypes
  script:
    """
        haplotype_utils convert-haplotypes-csv-to-tsv \
        --input ${infile} \
        --output haplotypes.tsv
    """
}
