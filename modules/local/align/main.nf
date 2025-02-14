process ALIGN {
    time '24h'
    cpus 1
    memory '8 GB'
    label 'process_high'

  input:
    tuple(
        val(cell_id),
        val(lanes),
        val(flowcells),
        path(fastqs1),
        path(fastqs2),
        path(primary_reference),
        val(primary_reference_version),
        val(primary_reference_name),
        path(primary_reference_fai),
        path(primary_reference_amb),
        path(primary_reference_ann),
        path(primary_reference_bwt),
        path(primary_reference_pac),
        path(primary_reference_sa)
    ) + (0..<secondary_references.size()).collect { i ->
        [
            path(secondary_references[i]),
            val(secondary_versions[i]),
            val(secondary_names[i]),
            path(secondary_references[i] + '.fai'),
            path(secondary_references[i] + '.amb'),
            path(secondary_references[i] + '.ann'),
            path(secondary_references[i] + '.bwt'),
            path(secondary_references[i] + '.pac'),
            path(secondary_references[i] + '.sa')
        ]
    } + [
        path(metadata)
    ]
  output:
    tuple(
        val(cell_id),
        path("aligned.bam"),
        path("aligned.bam.bai"),
        path("metrics.csv.gz"),
        path("metrics.csv.gz.yaml"),
        path("${cell_id}_gc_metrics.csv.gz"),
        path("${cell_id}_gc_metrics.csv.gz.yaml"),
        path("${cell_id}.tar.gz")
    )
  script:
    def lanes = lanes.join(' ')
    def flowcells = flowcells.join(' ')
    //def supplementary_2 = ''
    //if(secondary_reference_2_name) {
    //    supplementary_2 = '--supplementary_references ' + secondary_reference_2_name + ',' + secondary_reference_2_version + ',' + secondary_reference_2
    //} else {
    //    supplementary_2 = ''
    //}

    def supplementary_references_cmd = ''
    if (secondary_references) {
        def refs = []
        for (int i = 0; i < secondary_references.size(); i++) {
            refs << "${secondary_names[i]},${secondary_versions[i]},${secondary_references[i]}"
        }
        supplementary_references_cmd = "--supplementary_references " + refs.join(' ')
    }

    println "supplementary_references_cmd ${supplementary_references_cmd}"
    exit 1
    
    """

        fastqs_cmd=`python -c 'x=["${lanes}","${flowcells}","${fastqs1}","${fastqs2}"];x=[v.split() for v in x];x=[",".join(v) for v in zip(*x)];x=" --fastq_pairs ".join(x);print(x)'`

        alignment_utils alignment \
        --fastq_pairs \${fastqs_cmd} \
        --metadata_yaml ${metadata} \
        --reference ${primary_reference_name},${primary_reference_version},${primary_reference} \
        --supplementary_references ${secondary_reference_1_name},${secondary_reference_1_version},${secondary_reference_1} \
        ${supplementary_references_cmd} \
        --tempdir tempdir \
        --adapter1 CTGTCTCTTATACACATCTCCGAGCCCACGAGAC \
        --adapter2 CTGTCTCTTATACACATCTGACGCTGCCGACGA \
        --cell_id $cell_id \
        --wgs_metrics_mqual 20 \
        --wgs_metrics_bqual 20 \
        --wgs_metrics_count_unpaired false \
        --bam_output aligned.bam \
        --metrics_output metrics.csv.gz \
        --metrics_gc_output ${cell_id}_gc_metrics.csv.gz \
        --tar_output ${cell_id}.tar.gz \
        --num_threads ${task.cpus}

        rm -rf tempdir
    """
}
