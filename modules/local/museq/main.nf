process MUSEQ {
    time '48h'
    cpus 16
    memory '100 GB'
    label 'process_high'

  input:
    path(normal_bam)
    path(normal_bai)
    path(tumor_bam)
    path(tumor_bai)
    path(reference)
    path(reference_fai)
    val(max_coverage)
    val(interval)
    val(filename)
  output:
    path("${filename}.vcf.gz"), emit:vcf
    path("${filename}.vcf.gz.csi"), emit:csi
    path("${filename}.vcf.gz.tbi"), emit:tbi
  script:
    """
        mkdir pythonegg && export PYTHON_EGG_CACHE=$PWD/pythonegg

        if [[ ${task.cpus} -eq 1 ]]
        then
            museq normal:${normal_bam} tumour:${tumor_bam} reference:${reference} \
            --out merged.vcf --log museq.log -v -i ${interval}
            if [ \$? -ne 0 ]; then exit 1; fi
        else
            mkdir museq_vcf museq_log
            intervals=`variant_utils split-interval --interval ${interval} --num_splits ${task.cpus}`
            for interval in \${intervals}
                do
                    echo "museq normal:${normal_bam} tumour:${tumor_bam} reference:${reference} \
                    --out museq_vcf/\${interval}.vcf --log museq_log/\${interval}.log -v -i \${interval} ">> museq_commands.txt
                done
            parallel --jobs ${task.cpus} < museq_commands.txt
            if [ \$? -ne 0 ]; then exit 1; fi

            MUSEQ_VCF_FILES=\$(ls museq_vcf/*.vcf)
            variant_utils merge-vcf-files \\
                \$(for file in \$MUSEQ_VCF_FILES; do echo --inputs \$file; done) \\
                --output merged.vcf


        fi

        variant_utils fix-museq-vcf --input merged.vcf --output merged.fixed.vcf
        vcf-sort merged.fixed.vcf > merged.sorted.fixed.vcf
        bgzip merged.sorted.fixed.vcf -c > ${filename}.vcf.gz
        bcftools index ${filename}.vcf.gz
        tabix -f -p vcf ${filename}.vcf.gz
        if [ ! -f ${filename}.vcf.gz ]; then exit 1; fi
        if [ ! -f ${filename}.vcf.gz.tbi ]; then exit 1; fi
        if [ ! -f ${filename}.vcf.gz.csi ]; then exit 1; fi


    """

}
