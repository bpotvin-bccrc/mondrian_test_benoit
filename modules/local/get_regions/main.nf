process GETREGIONS {
    time '48h'
    cpus 1
    memory '6 GB'
    label 'process_high'


    input:
    path(reference)
    val(chromosomes)
    val(size)

    output:
    path('intervals.txt')

    script:
    chromosomes_arg = '--chromosomes ' + chromosomes.join(' --chromosomes ')
    """
    ls
    head ${reference}
    variant_utils generate-intervals --reference ${reference} ${chromosomes_arg} --size ${size} > intervals.txt
    """
}