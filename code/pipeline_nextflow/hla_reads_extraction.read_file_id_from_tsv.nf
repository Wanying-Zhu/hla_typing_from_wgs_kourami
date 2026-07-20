/* Author: Wanying Zhu

Extract the HLA reads from CRAM file and store in a BAM file
Preprocessing step for Kourami HLA calling
Example usage:
nextflow run hla_reads_extraction.nf -profile docker \
--sample_id <SAMPLE_ID> \
--cram_file <CRAM_FILE> \
--cram_ref <CRAM_REF> \
--kourami_db <KOURAMI_DB> \
--outdir <OUTDIR>

# From the Kourami container
SAMPLE_ID=R299996754
CRAM_FILE=/data/crams/R299996754.cram
CRAM_REF=/data/reference/GRCh38_full_analysis_set_plus_decoy_hla.fa
OUTDIR=kourami_test/

# Or on the beklow lab server
SAMPLE_ID=R299996754
CRAM_FILE=/belowshare/vumcshare/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/data/CRAM_example/R299996754.cram
CRAM_REF=/data100t1/home/wanying/shared_data_files/Illumina_reference/GRCh38_full_analysis_set_plus_decoy_hla.fa
OUTDIR=kourami_test/

# Enable docker by setting up the config file
nextflow run hla_reads_extraction.nf \
-profile docker \ 
--sample_id ${SAMPLE_ID} \
--cram_file ${CRAM_FILE} \
--cram_index ${CRAM_FILE}.crai \
--cram_ref ${CRAM_REF} \
--outdir ${OUTDIR}
*/

// Use the mordern DSL nextflow, requires both processes and workflow
nextflow.enable.dsl=2

// Pipeline parameters
// params.samplesheet = 'fil.285b3c14bec949144c3108dd7c93f989' // File ID: fil.285b3c14bec949144c3108dd7c93f989
params.samplesheet = 'fil.ed6d10c31c7a447ad67d08dec006baa0' // For testing: /wanying/cram_reference/agd_cram_file_ids_from_2025_q1_release.test_5_samples.tsv
params.sample_id = ''
params.cram_file = '' // Check using file ID directly, such as params.cram_file = 'fil.e1d940195cfb4506496a08dd5cea6966'
params.cram_index = '' // Check using file ID directly, such as params.cram_file = 'fil.9114d2042c6142a3e9c808dd5cea44db'
params.cram_ref = 'fil.d0a8266ac310465a5fff08deaaf769c0' // File ID for the reference CRAM file, or use /wanying/cram_reference/GRCh38_full_analysis_set_plus_decoy_hla.fa

// IMGT v3.24 (Iourami default): /wanying/kourami_hla_typing/imgt_hla_db/3_24/
// IMGT v3.64 (202604 release): /wanying/kourami_hla_typing/imgt_hla_db/3_64/
// params.kourami_db = ''

// params.outdir = '/wanying/kourami_hla_typing/chr6_hla_bams/'
params.outdir = 'kourami_test/'

process EXTRACT_HLA {
    // Extract HLA reads from CHR6 CRAM file
    // Docker image has been pushed to DockerHub: https://hub.docker.com/r/wanyingzhu/kourami-hla-tools
    publishDir params.outdir, mode: 'copy' // Change it to move once the test run is successful

    container 'wanyingzhu/kourami-hla-tools:1.0'
    // cpus 1
    // memory '512 MB'

    input:
    val sampleid
    path cram_file, stageAs: 'input.cram' // ← symlink, not copy this large file
    path cram_index, stageAs: 'input.cram.crai'  // ← symlink, not copy
    path cram_ref, stageAs: 'input.cram.reference' // ← symlink, not copy this large file

    output:
    path "${sampleid}.extract.bam"

    script:
    // Do not use bash 01_pull_hla_bam.sh ${sampleid} ${cram_file} ${cram_ref}
    // Use the symbolic link created above
    """
    echo "# Start extracting HLA reads from ${sampleid}"
    bash 01_pull_hla_bam.sh ${sampleid} input.cram input.cram.reference .
    echo "# Done"
    """
}

workflow {
    // Read from the sample sheet and create channel
    Channel
        .fromPath(params.samplesheet)
        .splitCsv(header: true, sep: '\t')
        .map { row -> tuple(
            row.sample_id,
            file(row.cram_id),           // ← ICA file ID
            file(row.cram_index_id),     // ← ICA file ID
            file(params.cram_ref)        // ← same reference for all samples
        )}
        .set { samples } // Store the channel in a variable (tuple) called "samples"

    EXTRACT_HLA(samples)
    // EXTRACT_HLA(
    //     params.sample_id,
    //     file(params.cram_file),
    //     file(params.cram_index),
    //     file(params.cram_ref)
    // )

}