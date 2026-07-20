# A warpper for the docker run

# Save the docker run into a bash file for easier setup in slurm
# Since I direct the output to a log file, need to create the folder first
# imgt_version=3.64
# sampleid=R299996754
# bam_path=/data/bams/workspace_extraction_40001-45000/R299996754.unsorted.extract.bam
# bash docker_run_kourami.skip_read_extraction.sh ${imgt_version} ${sampleid} ${bam_path}

imgt_version=$1
sampleid=$2
bam_path=$3
output_path=/data/output/kourami_run_${imgt_version}/${sampleid}

# Check if the docker image is loaded
if ! docker images -q wanyingzhu/kourami-hla-tools:1.0 | grep -q .; then
  echo -e "# Loading image...\n"
  # docker load -i /data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/code/docker/kourami-hla-tools-1.0.tar
  docker pull wanyingzhu/kourami-hla-tools:1.0
else
  echo -e "# Image already loaded, skipping loading.\n"
fi

docker run --rm \
-e output_path="/data/output/kourami_run_${imgt_version}/${sampleid}" \
-e sampleid="${sampleid}" \
-e imgt_version="${imgt_version}" \
-e bam_path="${bam_path}" \
--mount type=bind,src=/DC3/AGD250k_HLA_typing/extracted_hla_read_bams,dst=/data/bams,readonly \
--mount type=bind,src=/data100t1/home/wanying/shared_data_files/Illumina_reference,dst=/data/reference,readonly \
--mount type=bind,src=/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/data/kourami_reference,dst=/data/kourami_reference,readonly \
--mount type=bind,src=/DC3/AGD250k_HLA_typing/individual_hla_results,dst=/data/output \
--mount type=bind,src=/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/code,dst=/data/code \
wanyingzhu/kourami-hla-tools:1.0 \
bash -c 'if [ -f "${output_path}/done_kourami.log" ]; then
          echo "# Sample ${sampleid} already done, skipping."
          exit 0
        fi
        echo "# ################# Hostname: ${HOSTNAME} #################"
        mkdir -p "${output_path}" && bash /data/code/utils/run_kourami.skip_hla_read_extraction.sh "${imgt_version}" "${sampleid}" "${bam_path}"'

