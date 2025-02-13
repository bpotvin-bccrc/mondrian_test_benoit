process REMOVEBLACKLISTEDCALLS {
    time '48h'
    cpus 1
    memory '6 GB'
    label 'process_high'

  input:
    path(vcf_file)
    path(blacklist)
    val(filename)
  output:
    path("${filename}.vcf.gz"), emit: vcf
    path("${filename}.vcf.gz.tbi"), emit: tbi
  script:
    """
        io_utils exclude-blacklist --infile ${vcf_file} --outfile ${filename}.vcf \
        --exclusion_blacklist ${blacklist}
        bgzip ${filename}.vcf
        tabix ${filename}.vcf.gz
    """

}
