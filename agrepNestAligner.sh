#!/bin/bash


############################################### parse user-input ###############################################
# function to display usage/help message
usage() {
    echo -e "\nUsage: $0 -x <INT> -@ <INT> -i <input_FASTQ_file> -r <reference_database_directory> -o <output_directory>\n"
    echo -e "Aligns reads in a given FASTQ file to a reference database of ncRNAs using agrep.\n"
    echo "Options:"
    echo "  -x <maximum number of mismatches allowed>        Integer specifying the maximum number of mismatches allowed during alignment. Default = 0."
    echo "  -@ <number of threads>                           Integer specifying the number of threads to utilize. Default = 1."
    echo "  -i <input_FASTQ_file>                            Specifies the input FASTQ file. Mandatory argument."
    echo "  -r <reference_database_directory>                Path to the directory containing the reference database created from build_reference_database.sh. Mandatory argument."
    echo "  -o <output_directory>                            Specifies the directory the output TXT file should be written to. Mandatory argument."
    echo "  -h                                               Shows this help message."
    exit 1
}

# set default (i) maximum number of mismatches allowed and (ii) threads to use
N_MISMATCHES_ALLOWED=0
N_THREADS=1

# get user input
while getopts "h:@:i:o:r:x:" opt; do
    case $opt in
        h)
            usage;;
        @)
            N_THREADS=$OPTARG;;
        i)
            FASTQ=$OPTARG;;
        o)
            OUTPUT_DIR=$OPTARG;;
        r)
            REF=$OPTARG;;
        x)
            N_MISMATCHES_ALLOWED=$OPTARG;;
        *)
            usage;;
    esac
done

# ensure that the user passed all necessary parameters
if [[ -z "$FASTQ" && -z "$OUTPUT_DIR" && -z "$REF" ]]; then
    usage
elif [[ -z "$FASTQ" ]]; then
    echo -e "\nError: -i <input_FASTQ_file> is required"
    usage
elif [[ -z "$OUTPUT_DIR" ]]; then
    echo -e "\nError: -o <output_directory> is required"
    usage
elif [[ -z "$REF" ]]; then
    echo -e "\nError: -r <reference_database_directory> is required"
    usage
fi

# if no arguments are passed, then show the usage/help message
if [ $# -eq 0 ]; then
    usage
fi

# get path to output TXT file
SAMPLE_BASENAME=$(echo $(basename $FASTQ) | sed 's/.fastq//g')
OUTPUT_TXT=${OUTPUT_DIR}/${SAMPLE_BASENAME}_alignment.txt

# remove any previous alignment output directory
if [ -f "$OUTPUT_DIR" ]; then
    rm $OUTPUT_DIR
    echo -e "\nPrevious file ${OUTPUT_DIR} removed and will be rewritten"
fi

# create alignment output directory
mkdir -p $OUTPUT_DIR




############################################### get FASTQ file of unique reads ###############################################
# get FASTQ fie of unique reads
FASTQ_UNIQ=${FASTQ}.uniq
awk 'BEGIN {OFS="\n"}
{
    if (NR % 4 == 1) { header = $0 }
    if (NR % 4 == 2) { seq = $0 }
    if (NR % 4 == 3) { plus = $0 }
    if (NR % 4 == 0) { 
        qual = $0
        read = header "\n" seq "\n" plus "\n" qual
        if (!(seq in seen)) {
            print read
            seen[seq] = 1
        }
    }
}' $FASTQ > $FASTQ_UNIQ



############################################### create table summarizing duplicate read information ###############################################
# Extract sequence (line 2 of the 4 lines correspnding to read) and the read name (line 1 of the 4 lines corresponding to read)
N_DUPLICATED_READS_TABLE=${FASTQ_UNIQ}.n.dup.reads.table
TMP=$(mktemp)
awk 'NR % 4 == 1 {read_name=$0} NR % 4 == 2 {seq=$0; print seq, read_name}' "$FASTQ" > "$TMP"

# count occurrences of each unique sequence and create a semicolon-separated list of read names
awk '
{
    seq=$1
    read_name=$2
    count[seq]++
    read_names[seq] = (read_names[seq] == "" ? read_name : read_names[seq] ";" read_name)
}
END {
    for (seq in count) {
        print count[seq] "\t" seq "\t" read_names[seq]
    }
}
' "$TMP" > "$N_DUPLICATED_READS_TABLE"

# remove up the temporary file of sequences and read names
rm "$TMP"



############################################### loop through each read in the FASTQ file of unique reads ############################################### 
# disable globbing so that the asterisk symbol * isn't interpreted as wildcard when writing SAM file
set -f 

# for each individual read, there are four lines in the corresponding FASTQ file
N_READS=$(($(cat $FASTQ_UNIQ | wc -l) / 4))
echo "Number of unique reads: $N_READS"
echo "Total number of reads: $(($(cat $FASTQ | wc -l) / 4))"

# function to align a chunk of reads
align_chunk_reads() {

    # loop through the chunk of 10,000 unique reads
    for i in $(seq $START $END); do

        # get the line of the given read and quality scores in the FASTQ file
        LINE_READ=$((4*($i-1)+2))

        # extract each read along with its ID and quality scores
        #ID=$(sed -n "$LINE_ID{p}" $FASTQ_UNIQ | sed 's/@//g')
        READ_FORWARD=$(sed -n "$LINE_READ{p}" $FASTQ_UNIQ)

        # get the total number of duplicates of the given read
        N_DUPS=$(awk -v var="$READ_FORWARD" -F'\t' '$2==var {print $1}' $N_DUPLICATED_READS_TABLE)

        # get read in reverse
        READ_REVERSE=$(echo $READ_FORWARD | rev)

        # get the number of nucleotides in the given read
        N_NUCLEOTIDES_READ=${#READ_FORWARD}

        # determine whether read is aligned to any reference seqs with 0 mismatches, if not determine whether read is aligned to any reference seqs with 1 mismatch, ..., up to N_MISMATCHES mismatches
        ALIGNMENT_FLAG=false
        N_MISMATCHES_TMP=0
        while [ "$ALIGNMENT_FLAG" = false ]; do

            # FASTA file with all reference sequences of length N_NUCLEOTIDES_READ-N-N_MISMATCHES_ALLOWED to N_NUCLEOTIDES_READ+N_MISMATCHES_ALLOWED
            FASTA_TMP=${REF}/ref_n_${N_NUCLEOTIDES_READ}_x_${N_MISMATCHES_TMP}.fasta
            N_FASTA_TMP=$(cat $FASTA_TMP | wc -l)

            # get alignment of forward read (if applicable) and remove duplicates which can arise from multiple reference ncRNAs having the same nucleotide sequence
            FORWARD_ALIGNMENT=$(agrep --show-position -$N_MISMATCHES_TMP $READ_FORWARD $FASTA_TMP | tr ' ' '\n' | awk '!seen[$0]++' | tr '\n' ' ')
            #N_ALIGNMENTS_FORWARD=$(($(echo $FORWARD_ALIGNMENT | tr -cd ' ' | wc -c) + 1))
            for ALIGNMENT in $FORWARD_ALIGNMENT; do
                FORWARD_ALIGNMENT_REF_SEQ=$(echo $ALIGNMENT | awk -F':' '{print $2}')
                if ((${#FORWARD_ALIGNMENT_REF_SEQ} > 0)); then
                    # get name of reference sequence
                    REF_SEQ_NAME=$(cat $FASTA_TMP | grep -x -B 1 $FORWARD_ALIGNMENT_REF_SEQ | sed -n 's/^>\(.*\)/\1/p' | paste -sd '&' -)

                    # write alignment information as three tab-separated entries: nucleotide sequence, reference sequence name, and the number of duplicate reads in the given sample
                    ALIGNMENT=$(echo -e "$READ_FORWARD\t$REF_SEQ_NAME\t$N_DUPS")

                    # indicate that read has been aligned
                    ALIGNMENT_FLAG=true

                    # print alignment information so it can be appended to output file
                    echo $ALIGNMENT
                fi
            done

            # get alignment of reverse read (if applicable) and remove duplicates which can arise from multiple reference ncRNAs having the same nucleotide sequence
            if [ "$ALIGNMENT_FLAG" = false ]; then
                REVERSE_ALIGNMENT=$(agrep --show-position -$N_MISMATCHES_TMP $READ_REVERSE $FASTA_TMP | tr ' ' '\n' | awk '!seen[$0]++' | tr '\n' ' ')

                for ALIGNMENT in $REVERSE_ALIGNMENT; do
                    REVERSE_ALIGNMENT_REF_SEQ=$(echo $ALIGNMENT | awk -F':' '{print $2}')
                    if ((${#REVERSE_ALIGNMENT_REF_SEQ} > 0)); then
                        # get name of reference sequence
                        REF_SEQ_NAME=$(cat $FASTA_TMP | grep -x -B 1 $REVERSE_ALIGNMENT_REF_SEQ | sed -n 's/^>\(.*\)/\1/p' | paste -sd '&' -)

                        # write alignment information as three tab-separated entries: nucleotide sequence, reference sequence name, and the number of duplicate reads in the given sample
                        ALIGNMENT=$(echo -e "$READ_FORWARD\t$REF_SEQ_NAME\t$N_DUPS")

                        # indicate that read has been aligned
                        ALIGNMENT_FLAG=true

                        # print alignment information so it can be appended to output file
                        echo $ALIGNMENT
                    fi
                done
            fi

            # increase N_MISMATCHES_TMP by 1
            ((N_MISMATCHES_TMP++))

            # if there are no alignments to reference sequences with length in the interval [|read| - N_MISMATCHES_ALLOWED, |read| + N_MISMATCHES_ALLOWED], then the read is unmapped
            if (($N_MISMATCHES_TMP == (($N_MISMATCHES_ALLOWED+1)))) && [ "$ALIGNMENT_FLAG" = false ]; then

                # write alignment information in SAM file format
                #ALIGNMENT=$(echo -e "$READ_FORWARD\t*\t$N_DUPS")
                #echo $ALIGNMENT

                # indicate that the read has not been aligned
                ALIGNMENT_FLAG=true
            fi
        done
    done >> ${OUTPUT_DIR}/${SAMPLE_BASENAME}_x_${N_MISMATCHES_ALLOWED}_chunk_${n}.txt
}

# loop through N_CHUNKS and align 10,000 unique reads in each chunk
N_CHUNKS=$((N_READS / 10000))
for n in $(seq 1 $N_CHUNKS); do

    # get the start and end of the chunk of 10,000 unique reads
    START=$((($n - 1) * 10000 + 1))
    END=$(($n * 10000))
    
    # call the function align_chunk_reads and utilize any thread available
    align_chunk_reads $START $END $n &

    # don't try to run more computations on more than $N_THREADS threads at a time
    if (( $(jobs -r | wc -l) >= $N_THREADS )); then
        wait
    fi
done

# wait for all tasks to finish
wait 

# align the remaining unique reads
if (($(($N_CHUNKS * 10000)) < $N_READS)); then
    
    # get the start and end of the chunk of remaining unique reads
    START=$(($N_CHUNKS * 10000 + 1))
    END=$N_READS
    n=$(($N_CHUNKS + 1))

    # call the function align_chunk_reads
    align_chunk_reads $START $END $n
fi

# enable globbing
set +f

# consolidate the chunks of the alignments into a single file summarizing the overall alignment
cat ${OUTPUT_DIR}/${SAMPLE_BASENAME}_x_${N_MISMATCHES_ALLOWED}_chunk_* > $OUTPUT_TXT
rm ${OUTPUT_DIR}/${SAMPLE_BASENAME}_x_${N_MISMATCHES_ALLOWED}_chunk_*

# delete temporary FASTQ file of unique reads
rm $FASTQ_UNIQ

# delete temporary table of the number of duplicate reads in FASTQ file
rm $N_DUPLICATED_READS_TABLE


