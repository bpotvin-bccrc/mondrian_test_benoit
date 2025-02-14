nextflow.enable.dsl=2

include { CONCATCSV as CONCATREADS } from '../../modules/local/csverve_concat_csv'
include { CONCATCSV as CONCATSEGMENTS } from '../../modules/local/csverve_concat_csv'
include { CONCATCSV as CONCATPARAMS } from '../../modules/local/csverve_concat_csv'
include { CONCATCSV as CONCATMETRICS } from '../../modules/local/csverve_concat_csv'
include { CONCATCSV as CONCATGCMETRICS } from '../../modules/local/csverve_concat_csv'
include { CONCATCSV as CONCATALIGNMETRICS } from '../../modules/local/csverve_concat_csv'
include { BUILDTAR as HMMTAR } from '../../modules/local/tar'
include { BUILDTAR as ALIGNTAR } from '../../modules/local/tar'
include { ALIGN } from '../../modules/local/align'
include { CELLCYCLECLASSIFIER } from '../../modules/local/cell_cycle_classifier'
include { ADDCLUSTERINGORDER } from '../../modules/local/clustering_order'
include { PLOTHEATMAP } from '../../modules/local/heatmap'
include { HMMCOPY } from '../../modules/local/hmmcopy'
include { HTMLREPORT } from '../../modules/local/html_report'
include { BAMMERGECELLS } from '../../modules/local/merge_cells'
include { QCMETADATA } from '../../modules/local/qc_metadata'
include { RECOPY as RECOPYMETADATA } from '../../modules/local/recopy'

workflow MONDRIAN_QC{

    take:
        fastqs
        metadata_yaml
        primary_reference
        primary_reference_version
        primary_reference_name
        secondary_references
        secondary_versions
        secondary_names
        gc_wig
        map_wig
        quality_classifier_training_data
        repeats_satellite_regions
        chromosomes
        sample_id

    main:


    //println "primary_reference ${primary_reference}"
    //println "primary_reference_version ${primary_reference_version}"
    //println "primary_reference_name ${primary_reference_name}"
    //println "secondary_references ${secondary_references}"
    //println "secondary_versions ${secondary_versions}"
    //println "secondary_names ${secondary_names}"


    fastqs_data = Channel
               .fromPath(fastqs)
               .splitCsv(header:true, sep:',')

    lanes = fastqs_data.map{row -> tuple(row.cellid, row.laneid)}.groupTuple(by: 0)
    flowcells = fastqs_data.map{row -> tuple(row.cellid, row.flowcellid)}.groupTuple(by: 0)
    lanes1 = fastqs_data.map{row -> tuple(row.cellid, row.fastq1)}.groupTuple(by: 0)
    lanes2 = fastqs_data.map{row -> tuple(row.cellid, row.fastq2)}.groupTuple(by: 0)


    fastqs = lanes.join(flowcells).join(lanes1).join(lanes2).map { row ->
        // Create a tuple starting with the primary data
        def tuple = [
            row[0], row[1], row[2], row[3], row[4],
            primary_reference, primary_reference_version, primary_reference_name,
            primary_reference + '.fai', primary_reference + '.amb', primary_reference + '.ann',
            primary_reference + '.bwt', primary_reference + '.pac', primary_reference + '.sa'
        ]

        // Loop through secondary references, versions, and names and add them dynamically
        (0..<secondary_references.size()).each { i ->
            // Add the secondary reference, version, name and related files
            tuple += [
                secondary_references[i], secondary_versions[i], secondary_names[i],
                secondary_references[i] + '.fai', secondary_references[i] + '.amb', secondary_references[i] + '.ann',
                secondary_references[i] + '.bwt', secondary_references[i] + '.pac', secondary_references[i] + '.sa'
            ]
        }

        // Add metadata YAML at the end of the tuple
        tuple += [metadata_yaml]
        return tuple
    }

    //fastqs = lanes.join(flowcells).join(lanes1).join(lanes2).map{
    //    row -> tuple(
    //        row[0], row[1], row[2], row[3], row[4],
    //                   primary_reference, primary_reference_version, primary_reference_name,
    //                   primary_reference+'.fai', primary_reference+'.amb', primary_reference+'.ann',
    //                   primary_reference+'.bwt', primary_reference+'.pac', primary_reference+'.sa',
    //                   secondary_reference_1, secondary_reference_1_version, secondary_reference_1_name,
    //                   secondary_reference_1+'.fai', secondary_reference_1+'.amb', secondary_reference_1+'.ann',
    //                   secondary_reference_1+'.bwt', secondary_reference_1+'.pac', secondary_reference_1+'.sa',
    //                   secondary_reference_2, secondary_reference_2_version, secondary_reference_2_name,
    //                   secondary_reference_2+'.fai', secondary_reference_2+'.amb', secondary_reference_2+'.ann',
    //                   secondary_reference_2+'.bwt', secondary_reference_2+'.pac', secondary_reference_2+'.sa',
    //                   metadata_yaml
    //    )
    //}

    fastqs = lanes.join(flowcells).join(lanes1).join(lanes2).map{
        row -> tuple(
            row[0], row[1], row[2], row[3], row[4],
                       primary_reference, primary_reference_version, primary_reference_name,
                       primary_reference+'.fai', primary_reference+'.amb', primary_reference+'.ann',
                       primary_reference+'.bwt', primary_reference+'.pac', primary_reference+'.sa',
                       *secondary_references,
                       *secondary_versions,
                       *secondary_names,   
                       *secondary_indices,
                       metadata_yaml
        )
    }


    ALIGN(fastqs)

    CONCATALIGNMETRICS(ALIGN.out.collect{it[3]}, ALIGN.out.collect{it[4]}, sample_id+'_alignment_metrics', false)
    CONCATGCMETRICS(ALIGN.out.collect{it[5]}, ALIGN.out.collect{it[6]}, sample_id+'_gc_metrics', true)

    ALIGNTAR(ALIGN.out.collect{it[7]}, sample_id+'_alignment_data')

    hmm_input = ALIGN.out.map {
        it -> tuple(
            it[0],it[1],it[2], gc_wig, map_wig,
            primary_reference, primary_reference+'.fai',
            it[3],it[4],
            repeats_satellite_regions, quality_classifier_training_data,
            chromosomes, "0.9"
        )
    }

    HMMCOPY(hmm_input)

    HMMTAR(HMMCOPY.out.collect{it[9]}, sample_id+'_hmmcopy_data')

    CONCATREADS(HMMCOPY.out.collect{it[1]}, HMMCOPY.out.collect{it[2]}, sample_id+'_hmmcopy_reads', false)
    CONCATMETRICS(HMMCOPY.out.collect{it[3]}, HMMCOPY.out.collect{it[4]}, sample_id+'_metrics', false)
    CONCATPARAMS(HMMCOPY.out.collect{it[5]}, HMMCOPY.out.collect{it[6]}, sample_id+'_hmmcopy_params', false)
    CONCATSEGMENTS(HMMCOPY.out.collect{it[7]}, HMMCOPY.out.collect{it[8]}, sample_id+'_hmmcopy_segments', false)

    BAMMERGECELLS(
      ALIGN.out.collect{it[0]}, ALIGN.out.collect{it[1]}, ALIGN.out.collect{it[2]},
      primary_reference, primary_reference + '.fai',
      CONCATMETRICS.out.csv, CONCATMETRICS.out.yaml,
      sample_id
    )
    CELLCYCLECLASSIFIER(
        CONCATMETRICS.out.csv, CONCATMETRICS.out.yaml,
        CONCATREADS.out.csv, CONCATREADS.out.yaml,
    )

    ADDCLUSTERINGORDER(
        CELLCYCLECLASSIFIER.out.csv, CELLCYCLECLASSIFIER.out.yaml,
        CONCATREADS.out.csv, CONCATREADS.out.yaml,
        chromosomes, sample_id + '_hmmcopy_metrics'
    )

    PLOTHEATMAP(
        CONCATMETRICS.out.csv, CONCATMETRICS.out.yaml,
        CONCATREADS.out.csv, CONCATREADS.out.yaml,
        chromosomes, sample_id + '_heatmap'
    )

    HTMLREPORT(
        CONCATMETRICS.out.csv, CONCATMETRICS.out.yaml,
        CONCATGCMETRICS.out.csv, CONCATGCMETRICS.out.yaml,
        sample_id + '_qcreport'
    )

    QCMETADATA(
        BAMMERGECELLS.out.bam, BAMMERGECELLS.out.bai,
        BAMMERGECELLS.out.contaminated_bam, BAMMERGECELLS.out.contaminated_bai,
        BAMMERGECELLS.out.control_bam, BAMMERGECELLS.out.control_bai,
        CONCATGCMETRICS.out.csv, CONCATGCMETRICS.out.yaml,
        ADDCLUSTERINGORDER.out.csv, ADDCLUSTERINGORDER.out.yaml,
        CONCATPARAMS.out.csv, CONCATPARAMS.out.yaml,
        CONCATSEGMENTS.out.csv, CONCATSEGMENTS.out.yaml,
        CONCATREADS.out.csv, CONCATREADS.out.yaml,
        PLOTHEATMAP.out.pdf, HTMLREPORT.out.html,
        ALIGNTAR.out.tar, HMMTAR.out.tar,
        metadata_yaml
    )

    RECOPYMETADATA(QCMETADATA.out.metadata, 'metadata.yaml')

}
