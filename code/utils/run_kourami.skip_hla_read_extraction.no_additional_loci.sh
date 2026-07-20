# Skip the HLA reads extraction from CRAM (already done on ICA)
# Directly start from HLA reads in BAM files.
# !!! Need to run this using the docker container.
# This code is created from combining the two steps below

# imgt_version=3.64
# sampleid=R299996754
# bam_path=/data/bams/workspace_extraction_40001-45000/R299996754.unsorted.extract.bam
# kourami_db=/data/kourami_reference/imgt_hla_db/${imgt_version}
# output_path=/data/output/kourami_run_${imgt_version}
# docker run --rm \
# --mount type=bind,src=/DC3/AGD250k_HLA_typing/extracted_hla_read_bams,dst=/data/bams,readonly \
# --mount type=bind,src=/data100t1/home/wanying/shared_data_files/Illumina_reference,dst=/data/reference,readonly \
# --mount type=bind,src=/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/data/kourami_reference,dst=/data/kourami_reference,readonly \
# --mount type=bind,src=/DC3/AGD250k_HLA_typing/individual_hla_results,dst=/data/output \
# --mount type=bind,src=/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/code,dst=/data/code \
# kourami-hla-tools:1.0 \
# bash -c "mkdir -p ${output_path} && cd ${output_path} && /data/code/alignAndExtract_hs38DH_NoAlt.cram_input.bam_input.skip_read_extraction.sh -d ${kourami_db} ${sampleid} ${bam_path} ${output_path}"


# bam_fn=${output_path}/${sampleid}_on_KouramiPanel.bam
# kourami=/usr/local/kourami-0.9.6/build/Kourami.jar
# igmt_hla_reference=/data/kourami_reference/imgt_hla_db/${imgt_version}
# output_prefix=${output_path}/${sampleid}_out
# docker run --rm \
# --mount type=bind,src=/DC3/AGD250k_HLA_typing/extracted_hla_read_bams,dst=/data/crams,readonly \
# --mount type=bind,src=/data100t1/home/wanying/shared_data_files/Illumina_reference,dst=/data/reference,readonly \
# --mount type=bind,src=/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/data/kourami_reference,dst=/data/kourami_reference,readonly \
# --mount type=bind,src=/DC3/AGD250k_HLA_typing/individual_hla_results,dst=/data/output \
# --mount type=bind,src=/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/code,dst=/data/code \
# kourami-hla-tools:1.0 \
# java -jar ${kourami} -d ${igmt_hla_reference} -o ${output_prefix} -a ${bam_fn}


# ##########
# Example run of this code:
# imgt_version=3.64
# sampleid=R299996754
# bam_path=/data/bams/workspace_extraction_40001-45000/R299996754.unsorted.extract.bam
# kourami_db=/data/kourami_reference/imgt_hla_db/${imgt_version}
# output_path=/data/output/kourami_run_${imgt_version}
# docker run --rm \
# --mount type=bind,src=/DC3/AGD250k_HLA_typing/extracted_hla_read_bams,dst=/data/bams,readonly \
# --mount type=bind,src=/data100t1/home/wanying/shared_data_files/Illumina_reference,dst=/data/reference,readonly \
# --mount type=bind,src=/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/data/kourami_reference,dst=/data/kourami_reference,readonly \
# --mount type=bind,src=/DC3/AGD250k_HLA_typing/individual_hla_results,dst=/data/output \
# --mount type=bind,src=/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/code,dst=/data/code \
# kourami-hla-tools:1.0 \
# bash -c 



imgt_version=$1
sampleid=$2
bam_path=$3

kourami_db=/data/kourami_reference/imgt_hla_db/${imgt_version}
output_path=/data/output/kourami_run_${imgt_version}/${sampleid}

# ##### Sort and align bam reads #####
echo -e "# ############### Input bam generation (sort and align to IMGRT/HLA v${imgt_version}) ###############\n"
mkdir -p ${output_path} && \
cd ${output_path} && \
bash /data/code/alignAndExtract_hs38DH_NoAlt.cram_input.bam_input.skip_read_extraction.sh \
    -d ${kourami_db} ${sampleid} ${bam_path} ${output_path}

# ##### Run the Kourami HLA typing #####
echo -e '\n\n# ############### Start Kourami HLA typing ###############\n'
bam_fn=${output_path}/${sampleid}_on_KouramiPanel.bam
kourami=/usr/local/kourami-0.9.6/build/Kourami.jar
igmt_hla_reference=/data/kourami_reference/imgt_hla_db/${imgt_version}
output_prefix=${output_path}/${sampleid}_out

java -jar ${kourami} -d ${igmt_hla_reference} -o ${output_prefix} ${bam_fn} && \

# Create a log file to indicate the run is successful
touch ${output_path}/done_kourami.log
