# Modified by Wanying to adapt for CRAM input instead of BAM input
# Usage: bash alignAndExtract_hs38DH_NoAlt.for_cram_input_by_WZ.sh <sample_id> <bam_file> <kourami_ref_db>
# Example:
# bash alignAndExtract_hs38DH_NoAlt.for_cram_input_by_WZ.sh \
#     NA12878 \
#     NA12878.bam \
#     /data/kourami_reference \
#     /data/output/kourami_test_run

# Part of Kourami HLA typer/assembler
# (c) 2017 by  Heewook Lee, Carl Kingsford, and Carnegie Mellon University.
# See LICENSE for licensing.
#

#!/bin/bash

pushd `dirname $0` > /dev/null
SCRIPTD=`pwd`
popd > /dev/null

samtools_sort_memory_per_thread=2G
num_processors=8
kourami_db=$SCRIPTD/../db
me=`basename $0`


function usage {
    echo "HLA-related reads extractor for Kourami"
    echo "Note: Use this if you have bam file aligned to GRCh38 [NoAlt] (primary assembly + decoy + HLA from [bwa-kit] )"
    echo "USAGE: <PATH-TO>/$me -d [Kourami panel db] -r [refGenome] <sample_id> <bamfile>"
    echo
    echo " sample_id        : desired sample name (ex: NA12878) [required]"
    echo
    echo " bamfile          : sorted and indexed bam to hs38NoAltDH (ex: NA12878.bam) [required]"
    echo
    echo "------------------ Optional Parameters -----------------"
    echo " -d [panel DB]    : Path to Kourami panel db. [Default: db directory under Kourami installation kourami/db]"
    echo
    echo " -r [Ref Gemome]  : path to hs38NoAltDH (primary assembly + decoy + HLA [bwa-kit])" 
    echo "                    USE download_grch38.sh script to obtain the reference."
    echo "                    MUST BE BWA INDEXED prior to running this script."
    echo "                    If not given, it assumes, hs38NoAltDH.fa is in resources dir."
    echo
    echo " -h               : print this message."
    echo
    exit 1
}

# print usage when no argument is given
if [ $# -lt 1 ]; then
    usage
fi

while getopts :d:r:h FLAG; do
    case $FLAG in 
	d) 
	    kourami_db=$OPTARG
	    ;;
	h)
	    usage
	    ;;
	\?)
	    echo "Unrecognized option -$OPTARG. See usage:"
	    usage
	    ;;
    esac
done

shift $((OPTIND-1))

if [ $# -lt 2 ]; then
    echo "Missing one or more required arguments."
    usage
fi

sampleid=$1
bam_path=$2

echo "1. $bam_path"
echo "2. $kourami_db"
merged_hla_panel=$kourami_db/All_FINAL_with_Decoy.fa.gz
echo "3. $merged_hla_panel"

merged_hla_panel=$kourami_db/All_FINAL_with_Decoy.fa.gz
bam_for_kourami=$sampleid\_on_KouramiPanel.bam
samtools_bin=`(which samtools)`
bwa_bin=`(which bwa)`
bamUtil=`(which bam)`
if [ -z "$bamUtil" ]; then
    echo "missing bamUtil";
    echo "bamUtil available from https://github.com/statgen/bamUtil"
    exit 1;
fi
#bamUtil=$HOME/bamUtil_1.0.13/bamUtil-master/bin/bam 

if [ ! -x "$samtools_bin" ] || [ ! -x "$bwa_bin" ] || [ ! -x "$bamUtil" ];then
    echo "Please make sure samtools, bwa, and bamUtil are installed"
    exit 1
fi

if [ ! -e "$bam_path" ] || [ ! -e "$kourami_db" ] || [ ! -e "$merged_hla_panel" ];then
    echo "Missing one of the following files/directories (38DH):\n"
    echo "bam_path: $bam_path"
    echo "kourami_db: $kourami_db"
    echo "merged_hla_panel: $merged_hla_panel"
    exit 1
fi

echo ">>>>>>>>>>>>>>>> extracting reads mapping to HLA loci and ALT contigs (38DH_NoAlt)"
$samtools_bin sort --thread $num_processors -m $samtools_sort_memory_per_thread -O BAM -o "${sampleid}.extract.bam" "${bam_path}"

OUT=$?
if [ ! $OUT -eq 0 ];then
    echo 'Something went wrong while running bwa/samtools to align extracted reads to 38DH_NoAlt (38DH_NoAlt)'
    exit 1
fi

#rm $sampleid.tmp.extract*

echo ">>>>>>>>>>>>>> indexing extracted bam (38DH_NoAlt)"
$samtools_bin index $sampleid.extract.bam

echo ">>>>>>>>>>>>>> bamUtil fastq extraction (38DH_NoAlt)"
$bamUtil bam2FastQ --in $sampleid.extract.bam --gzip --firstOut ${sampleid}\_extract_1.fq.gz --secondOut ${sampleid}\_extract_2.fq.gz --unpairedOut ${sampleid}\_extract.unpaired.fq.gz &> /dev/null

OUT=$?
if [ ! $OUT -eq 0 ];then
    echo '$bamUtil fastq extraction Failed! (38DH_NoAlt)'
    exit 1
else
    rm $sampleid.extract.bam* ${sampleid}\_extract.unpaired.fq.gz
fi

echo ">>>>>>>>>>>>>> bwa mem to hla panel for Kourami "
$bwa_bin mem -t $num_processors $merged_hla_panel ${sampleid}\_extract_1.fq.gz ${sampleid}\_extract_2.fq.gz | $samtools_bin view -Sb - > $bam_for_kourami
OUT=$?
if [ ! $OUT -eq 0 ];then
    echo 'bwa alignment of extracted reads to HLA panel faild...'
    exit 1
fi
