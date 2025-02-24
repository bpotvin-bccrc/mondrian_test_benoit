process GETGENOMESIZE {
    time '48h'
    cpus 1
    memory '6 GB'
    label 'process_high'

  input:
    path(reference)
    path(reference_fai)
    val(chromosomes)
  output:
    path("genome_size.txt"), emit: txt
  script:
    def chromosomes = "--chromosomes " + chromosomes.join(" --chromosomes ")
    """
    variant_utils genome-size --reference ${reference} ${chromosomes} > genome_size.txt
    """

}
