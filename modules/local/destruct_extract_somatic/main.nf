process EXTRACTSOMATIC {
    time '48h'
    cpus 1
    memory '6 GB'
    label 'process_high'

    input:
    path(destruct_breakpoints)
    path(destruct_library)
    val(filename)

    output:
    path("${filename}_breakpoints.csv"), emit: breakpoints
    path("${filename}_library.csv"), emit: library

    script:
    """
        destruct extract_somatic \
        ${destruct_breakpoints} \
        ${destruct_library} \
        ${filename}_breakpoints.csv \
        ${filename}_library.csv \
        --control_ids normal
    """
}