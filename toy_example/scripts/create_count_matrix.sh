#!/bin/bash


############################################### parse user-input ###############################################
# function to display usage/help message
usage() {
    echo -e "\nUsage: $0 -i <input_directory>\n"
    echo -e "Consolidates agrepNestAligner alignment information into count matrix with rows corresponding to ncRNAs and columns corresponding to samples. The tab-delimited text file count_matrix.txt will be written to the input_directory argument.\n"
    echo "Options:"
    echo "  -i <input_directory>                             Specifies the directory the agrepNestAligner output was written to. Mandatory argument."
    echo "  -h                                               Shows this help message."
    exit 1
}

# get user input
while getopts "h:i:" opt; do
    case $opt in
        h)
            usage;;
        i)
            INPUT_DIR=$OPTARG;;
        *)
            usage;;
    esac
done

# if no arguments are passed, then show the usage/help message
if [ $# -eq 0 ]; then
    usage
fi


# get path to output TXT file of count matrix
if [[ "${INPUT_DIR: -1}" == "/" ]]; then
    OUTPUT_TXT=${INPUT_DIR}count_matrix.txt
else
    OUTPUT_TXT=${INPUT_DIR}/count_matrix.txt
fi






###############################################  for each sample, create temporary TXT file that sums counts for reads aligned to the same ncRNA. Note that this occurs because sometimes the forward and reverse read will align to the same reference ncRNA ###############################################
for SAMPLE_FILE in $INPUT_DIR/*_alignment.txt; do
    # path to temporary file which contains one row for each unique ncRNA with summed counts; note that there may be multiple rows corresponding to a single reference ncRNA in the original alignment files because of allowing for reads to align either in their forward or reverse orientations
    INPUT_FILE_UNIQ_ncRNAS=${SAMPLE_FILE}.uniq.ncRNAs.tmp

    # remove any previous file of the same name as INPUT_FILE_UNIQ_ncRNAs in case this script was run prior
    if [ -f "$INPUT_FILE_UNIQ_ncRNAS" ]; then
        rm $INPUT_FILE_UNIQ_ncRNAS
    fi

    # Initialize an associative array to hold the summed counts
    declare -A ncRNA_COUNTS

    # Read through the input file and sum counts for each miRNA
    while read -r SEQ ncRNA COUNT; do
        ncRNA_COUNTS["$ncRNA"]=$(( ${ncRNA_COUNTS["$ncRNA"]} + COUNT ))
    done < "$SAMPLE_FILE"

    # write the summed counts to the (temporary) output file
    for ncRNA in "${!ncRNA_COUNTS[@]}"; do
        echo -e "$ncRNA ${ncRNA_COUNTS[$ncRNA]}" >> "$INPUT_FILE_UNIQ_ncRNAS"
    done

    # clear the associate array ncRNA_COUNTS so counts from previous sample aren't included in the ncRNA counts of the current sample
    unset ncRNA_COUNTS
done





# get all unique ncRNAs sorted alphabetically
ncRNAs=$(cat $INPUT_DIR/*_alignment.txt | cut -d' ' -f2 | sort | uniq)
#echo ${ncRNAs[@]}

echo -n "ncRNA" > $OUTPUT_TXT

# add sample names to the header of the output count matrix
for SAMPLE_FILE in $INPUT_DIR/*_alignment.txt; do
    SAMPLE_NAME=$(basename "$SAMPLE_FILE")
    echo -n -e "\t$SAMPLE_NAME" | sed 's/_alignment.txt//g' >> "$OUTPUT_TXT"
done

# end header of output count matrix with a new line
echo "" >> "$OUTPUT_TXT"

# fill the output count matrix with ncRNA counts
for ncRNA in $ncRNAs; do
    # start the line with the ncRNA name
    echo -n "$ncRNA" >> "$OUTPUT_TXT"

    # loop through each sample file and get the count for the given ncRNA
    for SAMPLE_FILE in $INPUT_DIR/*_alignment.txt.uniq.ncRNAs.tmp; do
        # extract the count for the given ncRNA in the given sample
        COUNT=$(awk -v ncRNA="$ncRNA" '$1 == ncRNA {print $2}' "$SAMPLE_FILE")

        # if the ncRNA is not found in the given sample file, the count is 0
        if [ -z "$COUNT" ]; then
            COUNT=0
        fi

        # append the count to the current line
        echo -n -e "\t$COUNT" >> "$OUTPUT_TXT"
    done

    # end the line with a new line
    echo "" >> "$OUTPUT_TXT"
done


# remove temporary file of summed counts with unique reference ncRNAs
if [[ "${INPUT_DIR: -1}" == "/" ]]; then
    rm ${INPUT_DIR}*.uniq.ncRNAs.tmp
else
    rm ${INPUT_DIR}/*.uniq.ncRNAs.tmp
fi

echo "Count matrix written to $OUTPUT_TXT"


