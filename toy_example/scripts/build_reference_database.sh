#!/bin/bash

# function to display usage/help message
usage() {
    echo -e "\nUsage: $0 --min-nucleotides <INT> --max-nucleotides <INT> -x <INT> -r <reference_FASTA_file> -o <output_directory>\n"
    echo -e "Builds reference database corresponding to a reference FASTA file. This step is necessary prior to running agrepNestAligner.\n"
    echo "Options:"
    echo "  --min-nucleotides <INT>                          Integer value of the minimum number of nucleotides each reference sequence must contain to be considered, inclusive. Default = 18."
    echo "  --max-nucleotides <INT>                          Integer value of the maximum number of nucleotides each reference sequence must contain to be considered, inclusive. Default = 30."
    echo "  -x <maximum number of mismatches allowed>        Integer specifying the maximum number of mismatches allowed during alignment. Default = 0."
    echo "  -r <reference_FASTA_file>                        Specifies the FASTA file of reference sequences. Mandatory argument."
    echo "  -o <output_directory>                            Specifies the directory the reference database will be written to. Mandatory argument."
    echo "  -h                                               Shows this help message."
    exit 1
}

# set default lower and upper bound on the length of reference reads to consider
MIN_NUCLEOTIDES=18
MAX_NUCLEOTIDES=30

# set default maximum number of mismatches allowed
N_MISMATCHES_ALLOWED=0

# get user input
while [[ $# -gt 0 ]]; do
    case "$1" in
        --min-nucleotides)
             MIN_NUCLEOTIDES="$2"
             shift 2;;
        --max-nucleotides)
             MAX_NUCLEOTIDES="$2"
             shift 2;;
        -x)
             N_MISMATCHES_ALLOWED=$2
             shift 2;;
        -r)
             FASTA=$2
             shift 2;;
        -o)
             OUTPUT_DIR=$2
             shift 2;;
        -h)
             usage;;
        *)
             usage;;
    esac
done

# ensure that the user passed all necessary parameters
if [[ -z "$OUTPUT_DIR" && -z "$FASTA" ]]; then
    usage
elif [[ -z "$FASTA" ]]; then
    echo -e "\nError -r <reference_FASTA_file> is required"
    usage
elif [[ -z "$OUTPUT_DIR" ]]; then
    echo -e "\nError -o <output_directory> is required"
    usage
fi

# make output directory for reference database while overwriting existing directory if it exists
mkdir -p $OUTPUT_DIR

for N_MISMATCHES in $(seq 0 $N_MISMATCHES_ALLOWED); do
    for N_TMP in $(seq $MIN_NUCLEOTIDES $MAX_NUCLEOTIDES); do
        #echo "iteration $N_TMP"

        # get the lower and upper bounds on the number of nucleotides in reference sequences to consider
        export MIN_N_NUCLEOTIDES=$((N_TMP-N_MISMATCHES))
        export MAX_N_NUCLEOTIDES=$((N_TMP+N_MISMATCHES))

        # output FASTA file with all reference sequences of length N_TMP-N-N_MISMATCHES to N_TMP+N_MISMATCHES
        OUTPUT_FASTA=${OUTPUT_DIR}/ref_n_${N_TMP}_x_${N_MISMATCHES}.fasta

        # only consider reference sequences with length in the interval [N_TMP - N_MISMATCHES, N_TMP + N_MISMATCHES]
        awk 'BEGIN {min_length=ENVIRON["MIN_N_NUCLEOTIDES"]; max_length=ENVIRON["MAX_N_NUCLEOTIDES"]}
             /^>/ {if (seq) {if(length(seq) >= min_length && length(seq) <= max_length) print header "\n" seq} header = $0; seq=""}
             /^[^>]/ {seq = seq $0}
             END {if(length(seq) >= min_length && length(seq) <= max_length) print header "\n" seq}' $FASTA > $OUTPUT_FASTA
    done
done


