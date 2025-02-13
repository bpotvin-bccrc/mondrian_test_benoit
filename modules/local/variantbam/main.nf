process VARIANTBAM {
    time '48h'
    cpus 16
    memory '100 GB'
    label 'process_high'


    input:
        path(bam)
        path(bai)
        val(interval)
        val(max_coverage)

    output:
        path("output.bam"), emit: bam
        path("output.bam.bai"), emit: bai

    script:
    """
        if [[ ${task.cpus} -eq 1 ]]
        then
            variant ${bam} -m ${max_coverage} -k ${interval} -v -b -o output.bam
        else
            mkdir variant_bam
            split_intervals=`variant_utils split-interval --interval ${interval} --num_splits ${task.cpus}`
            for splitinterval in \${split_intervals}
                do
                    echo "variant ${bam} -m ${max_coverage} -k \${splitinterval} -v -b -o variant_bam/\${splitinterval}.bam" >> variant_commands.txt
                done
            parallel --jobs ${task.cpus} < variant_commands.txt
            sambamba merge -t ${task.cpus} output.bam variant_bam/*bam
        fi
        samtools index output.bam
    """

}