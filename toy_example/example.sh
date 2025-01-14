#!/bin/bash


# activate conda environment agrepNestAligner_env
#source ~/.bashrc
#conda activate agrepNestAligner_env


# get path to current working directory
CURRENT_DIRECTORY=$(pwd)


# build reference database
${CURRENT_DIRECTORY}/scripts/build_reference_database.sh \
  --min-nucleotides 16 \
  --max-nucleotides 120 \
  -x 1 \
  -r ${CURRENT_DIRECTORY}/data/reference_ncRNAs.fasta \
  -o ${CURRENT_DIRECTORY}/data/reference_ncRNAs_database



# extract UMI sequence, filter reads based on length, and align the four samples
echo -e "\nSample 1:"
umi_tools extract \
  --stdin=${CURRENT_DIRECTORY}/data/sample1.fastq \
  --log=${CURRENT_DIRECTORY}/data/sample1_umi_extraction_log_file.txt \
  --stdout=${CURRENT_DIRECTORY}/data/sample1_post_umi_extraction.fastq \
  --extract-method=regex \
  --bc-pattern='.+(?P<discard_1>AACTGTAGGCACCATCAAT){s<=2}(?P<umi_1>.{12})(?P<discard_2>.+)'

cutadapt \
  --minimum-length=16 \
  --maximum-length=120 \
  -o ${CURRENT_DIRECTORY}/data/sample1_post_cutadapt.fastq \
  ${CURRENT_DIRECTORY}/data/sample1_post_umi_extraction.fastq > ${CURRENT_DIRECTORY}/data/sample1_cutadapt_log_file.txt

${CURRENT_DIRECTORY}/scripts/agrepNestAligner.sh \
  -x 1 \
  -@ 1 \
  -i ${CURRENT_DIRECTORY}/data/sample1_post_cutadapt.fastq \
  -r ${CURRENT_DIRECTORY}/data/reference_ncRNAs_database \
  -o ${CURRENT_DIRECTORY}/data/alignment_output/x1

echo ""



echo -e "\nSample 2:"
umi_tools extract \
  --stdin=${CURRENT_DIRECTORY}/data/sample2.fastq \
  --log=${CURRENT_DIRECTORY}/data/sample2_umi_extraction_log_file.txt \
  --stdout=${CURRENT_DIRECTORY}/data/sample2_post_umi_extraction.fastq \
  --extract-method=regex \
  --bc-pattern='.+(?P<discard_1>AACTGTAGGCACCATCAAT){s<=2}(?P<umi_1>.{12})(?P<discard_2>.+)'

cutadapt \
  --minimum-length=16 \
  --maximum-length=120 \
  -o ${CURRENT_DIRECTORY}/data/sample2_post_cutadapt.fastq \
  ${CURRENT_DIRECTORY}/data/sample2_post_umi_extraction.fastq > ${CURRENT_DIRECTORY}/data/sample2_cutadapt_log_file.txt

${CURRENT_DIRECTORY}/scripts/agrepNestAligner.sh \
  -x 1 \
  -@ 1 \
  -i ${CURRENT_DIRECTORY}/data/sample2_post_cutadapt.fastq \
  -r ${CURRENT_DIRECTORY}/data/reference_ncRNAs_database \
  -o ${CURRENT_DIRECTORY}/data/alignment_output/x1

echo ""



echo -e "\nSample 3:"
umi_tools extract \
  --stdin=${CURRENT_DIRECTORY}/data/sample3.fastq \
  --log=${CURRENT_DIRECTORY}/data/sample3_umi_extraction_log_file.txt \
  --stdout=${CURRENT_DIRECTORY}/data/sample3_post_umi_extraction.fastq \
  --extract-method=regex \
  --bc-pattern='.+(?P<discard_1>AACTGTAGGCACCATCAAT){s<=2}(?P<umi_1>.{12})(?P<discard_2>.+)'

cutadapt \
  --minimum-length=16 \
  --maximum-length=120 \
  -o ${CURRENT_DIRECTORY}/data/sample3_post_cutadapt.fastq \
  ${CURRENT_DIRECTORY}/data/sample3_post_umi_extraction.fastq > ${CURRENT_DIRECTORY}/data/sample3_cutadapt_log_file.txt

${CURRENT_DIRECTORY}/scripts/agrepNestAligner.sh \
  -x 1 \
  -@ 1 \
  -i ${CURRENT_DIRECTORY}/data/sample3_post_cutadapt.fastq \
  -r ${CURRENT_DIRECTORY}/data/reference_ncRNAs_database \
  -o ${CURRENT_DIRECTORY}/data/alignment_output/x1

echo ""



echo -e "\nSample 4:"
umi_tools extract \
  --stdin=${CURRENT_DIRECTORY}/data/sample4.fastq \
  --log=${CURRENT_DIRECTORY}/data/sample4_umi_extraction_log_file.txt \
  --stdout=${CURRENT_DIRECTORY}/data/sample4_post_umi_extraction.fastq \
  --extract-method=regex \
  --bc-pattern='.+(?P<discard_1>AACTGTAGGCACCATCAAT){s<=2}(?P<umi_1>.{12})(?P<discard_2>.+)'

cutadapt \
  --minimum-length=16 \
  --maximum-length=120 \
  -o ${CURRENT_DIRECTORY}/data/sample4_post_cutadapt.fastq \
  ${CURRENT_DIRECTORY}/data/sample4_post_umi_extraction.fastq > ${CURRENT_DIRECTORY}/data/sample4_cutadapt_log_file.txt

${CURRENT_DIRECTORY}/scripts/agrepNestAligner.sh \
  -x 1 \
  -@ 1 \
  -i ${CURRENT_DIRECTORY}/data/sample4_post_cutadapt.fastq \
  -r ${CURRENT_DIRECTORY}/data/reference_ncRNAs_database \
  -o ${CURRENT_DIRECTORY}/data/alignment_output/x1

echo ""



# consolidate alignment information to create count matrix with rows corresponding to ncRNAs and columns corresponding to samples
${CURRENT_DIRECTORY}/scripts/create_count_matrix.sh \
  -i ${CURRENT_DIRECTORY}/data/alignment_output/x1/

echo ""


