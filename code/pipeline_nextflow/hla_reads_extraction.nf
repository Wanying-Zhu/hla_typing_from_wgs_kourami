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


# Using container in a interactive mode
docker run --rm --mount type=bind,src=/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/data/CRAM_example,dst=/data/crams,readonly --mount type=bind,src=/data100t1/home/wanying/shared_data_files/Illumina_reference,dst=/data/reference,readonly --mount type=bind,src=/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/data/kourami_reference,dst=/data/kourami_reference,readonly --mount type=bind,src=/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/output,dst=/data/output --mount type=bind,src=/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/code,dst=/data/code kourami-hla-tools:1.0 bash -c "nextflow run /data/code/pipeline_nextflow/hla_reads_extraction.nf -profile docker  --sample_id ${SAMPLE_ID} --cram_file ${CRAM_FILE} --cram_index ${CRAM_FILE}.crai --cram_ref ${CRAM_REF} --outdir ${OUTDIR} "

*/

// Use the mordern DSL nextflow, requires both processes and workflow
nextflow.enable.dsl=2

// Pipeline parameters
params.sample_id = ''
params.cram_file = ''
params.cram_index = ''
params.cram_ref = ''

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
    bash 01_pull_hla_bam.sh ${sampleid} input.cram input.cram.reference
    echo "# Done"
    """
}

workflow {

    EXTRACT_HLA(
        params.sample_id,
        file(params.cram_file),
        file(params.cram_index),
        file(params.cram_ref)
    )

}