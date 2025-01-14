# agrepNestAligner

Alignment algorithm designed specifically for aligning small RNA-sequencing data to database of non-coding RNAs (ncRNAs).

## Table of Contents
- [1. Motivation for agrepNestAligner](#motivation)
- [2. Installation](#installation)
- [3. Usage](#usage)
   - [3.1. Suggested preprocessing](#preprocessing)
   - [3.2 Build reference database](#build-ref-db)
   - [3.3 Run agrepNestAligner](#run-aligner)
   - [3.4 Create count matrix](#create-count-matrix)
- [4. Downstream analysis](#downstream-analysis)

<a name="motivation"></a>
## 1. Motivation for agrepNestAligner
Common bioinformatics workflows which process small RNA-sequencing data typically involve using an aligner such as Burrows-Wheeler Aligner (BWA) or Bowtie to align reads to a database of non-coding RNAs (ncRNAs) such as miRbase. In a database of ncRNAs such as miRbase for example, it is often the case that a hairpin microRNA (miRNA) contains an subsequence equivalent to a mature miRNA (e.g. hsa-mir-12117=GTCTCAGT**GAAGTGGAGCACATCAGTGA**AAGGGTGAACTTAACCTTTCACTGGTGTGCTCCATCTCACTCAGAC contains hsa-miR-12117=GAAGTGGAGCACATCAGTGA). If a small RNA-sequencing read is exactly equivalent to a mature miRNA such as hsa-miR-12117 after the unique molecular identifier (UMI) is removed and either BWA or Bowtie is used to align the given read to a database containing both the mature and hairpin miRNA, then the read will often be aligned to the hairpin miRNA even though the read exactly matches the mature miRNA. This is the case because BWA, Bowtie, and other common aligners are designed to align reads to the human genome where reference sequences are not exact subsequences of each other (e.g. chromosome 13 is not an exact subsequence of chromosome 17). The alignment tool agrepNestAligner is a more biologically-relevant aligner specifically for aligning small RNA-sequencing data to a database of ncRNAs which accounts for the nuances of nested reference sequences.

<a name="installation"></a>
## 2. Installation
The dependencies of agrepNestAligner are tre-agrep, sed, and awk. All UNIX-based operating systems typically have sed and awk installed by default, so only tre-agrep must be installed. Note that tre-agrep is used instead of grep becaue tre-agrep allows the user to input a maximum number of mismatches when matching regular expressions. However, if you would like to (i) extract the unique molecular identifier (UMI) sequences from reads and (ii) filter reads based on length (i.e. number of nucleotides) as is recommended by both us and Kapoor et al in "A bioinformatics approach to microRNA-sequencing analysis" ([https://www.sciencedirect.com/science/article/pii/S266591312030131X](https://www.sciencedirect.com/science/article/pii/S266591312030131X)), then umi_tools and cutadapt must also be installed. We recommend creating a conda environment with the necessary dependencies, which can be done executing the following command once conda is installed on your system, you have downloaded this repository, and have navigated to the directory that contains the environment.yml file:
```
conda env create -f environment.yml
```
To activate the agrepNestAligner_env environment, run:
```
conda activate agrepNestAligner_env
```
To deactivate the agrepNestAligner_env conda environement, run:
```
conda deactivate
```
For instructions on installing conda on your system, see [https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html).

<a name="usage"></a>
## 3. Usage

<a name="preprocessing"></a>
### 3.1. Suggested preprocessing
We recommend performing the first two steps of data preprocessing proposed by Kapoor et al in "A bioinformatics approach to microRNA-sequencing analysis" ([https://www.sciencedirect.com/science/article/pii/S266591312030131X](https://www.sciencedirect.com/science/article/pii/S266591312030131X)) which involve (i) extracting unique molecular identifiers (UMIs) from reads in the original FASTQ files and (ii) filtering reads to keep only reads with a length (i.e. number of nucleotides) in a specified range. If human hairpin and mature miRNAs from miRbase are used as the reference database, then we recommend retaining reads with length 16-120, inclusive, because this is the range of nucleotide sequence length in miRbase's human hairpin and mature miRNAs.
```
umi_tools extract \
  --stdin=$RAW_FASTQ \
  --log=$UMI_EXTRACTION_LOG_FILE \
  --stdout=$UMI_EXTRACTED_FASTQ \
  --extract-method=regex \
  --bc-pattern='.+(?P<discard_1>AACTGTAGGCACCATCAAT){s<=2}(?P<umi_1>.{12})(?P<discard_2>.+)'

cutadapt \
  --minimum-length=16 \
  --maximum-length=120 \
  -o $POST_CUTADAPT_FASTQ \
  $UMI_EXTRACTED_FASTQ > $CUTADAPT_LOG_FILE
```

<a name="build-ref-db"></a>
### 3.2. Build reference database
Building a reference database from the reference FASTA file greatly increases speed and is a necessary step in using agrepNestAligner. If the length of the shortest/longest read in the reference FASTA file is S/L and the maximum number of mismatches allowed is N, then a FASTA file with all reads of length M-N to M+N for each M=S,S+1,S+2,...,L-2,L-1,L is created, resulting in (L-S)+1 FASTA files. For a given read in some sample's FASTQ file with length A, the specific FASTA file with all reads of length A-N to A+N is used as the reference to avoid regular expression matching with agrep on reference sequences that are either too short or too long to correspond to the given read. 

To see the usage of the script build_reference_database.sh, run:
```
/insert_path/build_reference_database.sh -h
```
Output:
Usage: ./build_reference_database.sh --min-nucleotides <INT> --max-nucleotides <INT> -x <INT> -r <reference_FASTA_file> -o <output_directory>

Options:
  --min-nucleotides <INT>                          Integer value of the minimum number of nucleotides each reference sequence must contain to be considered, inclusive. Default = 18.
  --max-nucleotides <INT>                          Integer value of the maximum number of nucleotides each reference sequence must contain to be considered, inclusive. Default = 30.
  -x <maximum number of mismatches allowed>        Integer specifying the maximum number of mismatches allowed during alignment. Default = 0.
  -r <reference_FASTA_file>                        Specifies the FASTA file of reference sequences. Mandatory argument.
  -o <output_directory>                            Specifies the directory the reference database will be written to. Mandatory argument.
  -h                                               Shows this help message.

```
/insert_path/build_reference_database.sh \
  --min-nucleotides 16 \
  --max-nucleotides 120 \
  -x 1 \
  -r $REFERENCE_ncRNAS_FASTA \
  -o $REFERENCE_ncRNA_DATABASE_DIRECTORY
```

<a name="run-aligner"></a>
### 3.3. Run agrepNestAligner
```
/insert_path/agrepNestAligner.sh \
  -x 1 \
  -@ 1 \
  -i $POST_CUTADAPT_FASTQ \
  -r $REFERENCE_ncRNA_DATABASE_DIRECTORY \
  -o $ALIGNMENT_OUTPUT_DIRECTORY
```

<a name="create-count-matrix"></a>
### 3.4. Create count matrix
```
/insert_path/create_count_matrix.sh \
  -i ALIGNMENT_OUTPUT_DIRECTORY
```

<a name="downstream-analysis"></a>
## 4. Downstream analysis
Once the count matrix with rows corresponding to ncRNAs and columns corresponding to samples is computed, there are a variety of tools available which perform differential transcription analysis to identify ncRNAs transcribed in significantly different levels among sample groups of interest, most of which use negative binomial regression. Some options include DESeq2, edgeR, or limma.


