# Start the kourami docker in -it mode and run this code
# Example:
# bash docker_it_run_kourami.sh 3.64 R299996754 /data/bams/workspace_extraction_40001-45000/R299996754.unsorted.extract.bam

imgt_version=$1 # 3.64
sampleid=$2 # R299996754
bam_path=$3 # /data/bams/workspace_extraction_40001-45000/R299996754.unsorted.extract.bam
output_path="/data/output/kourami_run_${imgt_version}/${sampleid}"

if [ -f "${output_path}/done_kourami.log" ]; then
    echo "# Sample ${sampleid} already done, skipping."
    exit 0
fi

mkdir -p "${output_path}" && bash /data/code/utils/run_kourami.skip_hla_read_extraction.no_additional_loci.sh "${imgt_version}" "${sampleid}" "${bam_path}"