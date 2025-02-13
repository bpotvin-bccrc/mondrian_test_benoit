nextflow.enable.dsl=2

////////////////////////////////////////////////////
/* --          VALIDATE INPUTS                 -- */
////////////////////////////////////////////////////

def assert_required_param(param, param_name){
    if(! param){
        exit 1, param_name +' not specified. Please provide --${param_name} <value> !'
    }
}
assert_required_param(params.primary_reference, 'primary_reference')
assert_required_param(params.primary_reference_version, 'primary_reference_version')
assert_required_param(params.primary_reference_name, 'primary_reference_name')
assert_required_param(params.secondary_reference_1, 'secondary_reference_1')
assert_required_param(params.secondary_reference_1_version, 'secondary_reference_1_version')
assert_required_param(params.secondary_reference_1_name, 'secondary_reference_1_name')
assert_required_param(params.gc_wig, 'gc_wig')
assert_required_param(params.map_wig, 'map_wig')
assert_required_param(params.quality_classifier_training_data, 'quality_classifier_training_data')
assert_required_param(params.repeats_satellite_regions, 'repeats_satellite_regions')
assert_required_param(params.chromosomes, 'chromosomes')
assert_required_param(params.fastqs, 'fastqs')
assert_required_param(params.metadata, 'metadata')
assert_required_param(params.sample_id, 'sample_id')

primary_reference = file(params.primary_reference)
primary_reference_version = params.primary_reference_version
primary_reference_name = params.primary_reference_name
secondary_reference_1 = file(params.secondary_reference_1)
secondary_reference_1_version = params.secondary_reference_1_version
secondary_reference_1_name = params.secondary_reference_1_name
gc_wig = file(params.gc_wig)
map_wig = file(params.map_wig)
quality_classifier_training_data = file(params.quality_classifier_training_data)
repeats_satellite_regions = file(params.repeats_satellite_regions)
chromosomes = params.chromosomes
fastqs = file(params.fastqs)
metadata = file(params.metadata)
sample_id = params.sample_id

println "Params Keys: ${params.keySet()}"

def secondary_references = []
def secondary_versions = []
def secondary_names = []

(1..10).each { i ->
    def referenceKey = "secondary_reference_${i}"
    def versionKey = "secondary_reference_${i}_version"
    def nameKey = "secondary_reference_${i}_name"
    
    // Debugging print to see the values in params for the keys
    println "Checking: ${referenceKey}, ${versionKey}, ${nameKey}"
    println "Value: ${params[secondary_reference_${i}}], ${params.versionKey}, ${params.nameKey}"
    exit 1
    // Check if all keys exist in the params object and are not null
    def ref = params[referenceKey]
    def version = params[versionKey]
    def name = params[nameKey] ?: "default_name" // Using a default if missing

    // If the reference exists
    if (ref) {
        secondary_references << file(ref)
        secondary_versions << version
        secondary_names << name
        
        // Debugging output to see what is being added
        println "Found secondary reference ${i}: ${ref}, version: ${version}, name: ${name}"
    } else {
        println "Missing reference for ${referenceKey}"
    }
}

// Print the resulting lists
println "Secondary Names: ${secondary_names}"
exit 1

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { MONDRIAN_QC         } from '../subworkflows/local/qc'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow MONDRIAN_QC_PIPELINE{



    MONDRIAN_QC(
        fastqs,
        metadata,
        primary_reference,
        primary_reference_version,
        primary_reference_name,
        secondary_references,        
        secondary_versions,
        secondary_names,
        gc_wig,
        map_wig,
        quality_classifier_training_data,
        repeats_satellite_regions,
        chromosomes,
        sample_id
    )

}
