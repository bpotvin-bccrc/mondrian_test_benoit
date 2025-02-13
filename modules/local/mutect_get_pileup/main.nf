process GETPILEUP {
    time '48h'
    cpus 4
    memory '24 GB'
    label 'process_high'

  input:
    path(bam)
    path(reference)
    path(reference_fai)
    path(reference_dict)
    path(variants_for_contamination)
    path(variants_for_contamination_idx)
    val(chromosome)
    val(filename)
  output:
    path("${filename}.table"), emit: table
  script:
    def chromosomes = chromosome.collect { "-L " + it }.join(' ')
    """
        mkdir outdir
        gatk GetPileupSummaries \
        -R ${reference} -I ${bam} \
        ${chromosomes} \
        -V ${variants_for_contamination} \
        -O ${filename}.table
    """
}
