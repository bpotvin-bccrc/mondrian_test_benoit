process MUTECT {
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
    path(reference_dict)
    path(panel_of_normals)
    path(panel_of_normals_idx)
    path(gnomad)
    path(gnomad_idx)
    val(interval)
    val(filename)
  output:
    path("${filename}.vcf.gz"), emit: vcf
    path("${filename}.vcf.gz.tbi"), emit: tbi
    path("${filename}.stats"), emit: stats
    path("raw_data/*_f1r2.tar.gz"), emit: f1r2
  script:
    """
        set -e

        gatk GetSampleName -R ${reference} -I ${normal_bam} -O normal_name.txt
        mkdir raw_data

        if [[ ${task.cpus} -eq 1 ]]
        then
            gatk Mutect2 \
            -I ${normal_bam} -normal `cat normal_name.txt` \
            -I ${tumor_bam}  \
            -pon ${panel_of_normals} \
            --germline-resource  ${gnomad} \
            --f1r2-tar-gz raw_data/${interval}_f1r2.tar.gz \
            -R ${reference} -O raw_data/${interval}.vcf  --intervals ${interval}
            mv raw_data/${interval}.vcf merged.vcf
            mv raw_data/${interval}.vcf.stats ${filename}.stats
        else
            intervals=`variant_utils split-interval --interval ${interval} --num_splits ${task.cpus}`
            for interval in intervals
                do
                    echo "gatk Mutect2 \
                    -I ${normal_bam} -normal `cat normal_name.txt` \
                    -I ${tumor_bam}  \
                    -pon  ${panel_of_normals} \
                    --germline-resource  ${gnomad} \
                    --f1r2-tar-gz raw_data/${interval}_f1r2.tar.gz \
                    -R ${reference} -O raw_data/${interval}.vcf.gz  --intervals ${interval} ">> commands.txt
                done
            parallel --jobs ${task.cpus} < commands.txt
            

            VCF_GZ_FILES=\$(ls raw_data/*.vcf.gz)
            variant_utils merge-vcf-files \\
                \$(for file in \$VCF_GZ_FILES; do echo --inputs \$file; done) \\
                --output merged.vcf


            STATS_FILES=\$(ls raw_data/*.stats)
            gatk --java-options "-Xmx4G" MergeMutectStats \\
                \$(for file in \$STATS_FILES; do echo -stats \$file; done) \\
                -O ${filename}.stats

        fi

        variant_utils fix-museq-vcf --input merged.vcf --output merged.fixed.vcf
        vcf-sort merged.fixed.vcf > ${filename}.vcf
        bgzip ${filename}.vcf -c > ${filename}.vcf.gz
        tabix -f -p vcf ${filename}.vcf.gz
    """

}
