process GENERATECHROMDEPTH {
    time '48h'
    cpus 1
    memory '6 GB'
    label 'process_high'

  input:
    path(bam)
    path(bai)
    path(reference)
    path(reference_fai)
    val(chromosomes)
  output:
    path("chrom_depth.txt"), emit: txt
  script:
    def chromosomes = chromosomes.join(" ")
    """
        mkdir raw_data
        for interval in ${chromosomes}
            do
                GetChromDepth --align-file ${bam} --chrom \${interval} --output-file raw_data/\${interval}.chrom_depth.txt
            done
        
        input_files=\$(ls raw_data/*.chrom_depth.txt)
        input_string=\$(for file in \$input_files; do echo --inputs \$file; done | tr '\\n' ' ')

        variant_utils merge-chromosome-depths-strelka \$input_string --output chrom_depth.txt
    """

}
