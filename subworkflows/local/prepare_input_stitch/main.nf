workflow PREPARE_INPUT_STITCH {

    take:
    ch_posfile       // channel:   [ [chr], posfile ]
    ch_fasta         // channel:   [ [genome], fa, fai ]
    ch_input_impute  // channel:   [ [id, chr, region], bam, bai ]

    main:

    ch_versions      = Channel.empty()

    // Value channels
    def input_empty         = [[]]
    def rdata_empty         = [[]]
    k_val                   = params.k_val
    ngen                    = params.ngen

    // Get chromosomes of posfile
    ch_posfile = ch_posfile.map{meta, posfile -> return[['chr': meta.chr], posfile]}

    // Get chromosomes of fasta
    ch_chromosomes = ch_fasta.map{it -> it[2]}
                    .splitCsv(header: ["chr", "size", "offset", "lidebase", "linewidth", "qualoffset"], sep: "\t")
                    .map{it -> return [[chr: it.chr], it.chr]}

    // Make final channel with parameters
    stitch_parameters = ch_posfile.map { it + input_empty + rdata_empty}
                    .join(ch_chromosomes)
                    .map { it + k_val + ngen}

    // Prepare sample files for STITCH
    // Group input by ID
    ch_bam_bai = ch_input_impute.map {meta, bam, bai -> [[meta.id], bam, bai]}.unique()

    // Make bamlist from bam input
    ch_bamlist = ch_bam_bai
                    .map {it[1].tokenize('/').last()}
                    .collectFile(name: "bamlist.txt", newLine: true, sort: true)

    // Collect all files
    stitch_samples = ch_bam_bai.map {meta, bam, bai -> [["id": "all_samples"], bam, bai]}
                    .groupTuple()
                    .combine(ch_bamlist)
                    .collect()

    emit:
    stitch_parameters = stitch_parameters // channel:   [ [chr], posfile, [], [], chr, k_val, ngen ]
    stitch_samples    = stitch_samples    // channel:   [ [id], bam, bai, bamlist ]
    versions          = ch_versions       // channel:   [ versions.yml ]

}
