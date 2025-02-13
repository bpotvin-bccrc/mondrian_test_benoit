process RECOPY {
    time '48h'
    cpus 1
    memory '6 GB'
    label 'process_high'

  input:
    path(input_path, stageAs: "?/*")
    val(filename)
  output:
    path("${filename}"), emit: output_path
  script:
    """
        cp ${input_path} ${filename}
    """
}
