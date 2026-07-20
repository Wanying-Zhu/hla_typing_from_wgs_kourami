# Convert/load the image if the .sif file doesn't exist
SIF=/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/code/singularity/kourami-hla-tools.sif

imgt_version=$1
sampleid=$2
bam_path=$3
output_path=/data/output/kourami_run_${imgt_version}/${sampleid}
echo "# ################# Hostname: ${HOSTNAME} #################"

SINGULARITYENV_output_path="/data/output/kourami_run_${imgt_version}/${sampleid}" \
SINGULARITYENV_sampleid="${sampleid}" \
SINGULARITYENV_imgt_version="${imgt_version}" \
SINGULARITYENV_bam_path="${bam_path}" \
singularity exec \
    -B /DC3/AGD250k_HLA_typing/extracted_hla_read_bams:/data/bams:ro \
    -B /data100t1/home/wanying/shared_data_files/Illumina_reference:/data/reference:ro \
    -B /data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/data/kourami_reference:/data/kourami_reference:ro \
    -B /DC3/AGD250k_HLA_typing/individual_hla_results:/data/output \
    -B /data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/code:/data/code \
    "$SIF" \
    bash -c 'if [ -f "${output_path}/done_kourami.log" ]; then
                echo "# Sample ${sampleid} already done, skipping."
                exit 0
            fi
            mkdir -p "${output_path}" && bash /data/code/utils/run_kourami.skip_hla_read_extraction.no_additional_loci.sh "${imgt_version}" "${sampleid}" "${bam_path}"'