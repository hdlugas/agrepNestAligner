# agrepNestAligner

Alignment algorithm designed specifically for aligning small RNA-sequencing data to database of non-coding RNAs (ncRNAs).

## Table of Contents
- [1. Motivation for agrepNestAligner](#motivation)
- [2. Installation](#installation)
- [3. Usage](#usage)
   - [3.1 Build reference database index](#build-ref-db-index)
   - [3.2 Run agrepNestAligner](#run-aligner)

<a name="motivation"></a>
## 1. Motivation for agrepNestAligner
Common bioinformatics workflows which process small RNA-sequencing data typically involve using an aligner such as Burrows-Wheeler Aligner (BWA) or Bowtie to align reads to a database of non-coding RNAs (ncRNAs) such as miRbase. In a database of ncRNAs such as miRbase for example, it is often the case that a hairpin microRNA (miRNA) contains an subsequence equivalent to a mature miRNA (e.g. hsa-mir-12117=GTCTCAGT**GAAGTGGAGCACATCAGTGA**AAGGGTGAACTTAACCTTTCACTGGTGTGCTCCATCTCACTCAGAC contains hsa-miR-12117=GAAGTGGAGCACATCAGTGA). If a small RNA-sequencing read is exactly equivalent to a mature miRNA such as hsa-miR-12117 after the unique molecular identifier (UMI) is removed and either BWA or Bowtie is used to align the given read to a database containing both the mature and hairpin miRNA, then the read will often be aligned to the hairpin miRNA even though the read exactly matches the mature miRNA. This is the case because BWA, Bowtie, and other common aligners are designed to align reads to the human genome where reference sequences are not exact subsequences of each other (e.g. chromosome 13 is not an exact subsequence of chromosome 17). The alignment tool agrepNestAligner is a more biologically-relevant aligner specifically for aligning small RNA-sequencing data to a database of ncRNAs which accounts for the nuances of nested reference sequences.

<a name="installation"></a>
## 2. Installation
The dependencies of agrepNestAligner are tre-agrep, sed, and awk. All UNIX-based operating systems typically have sed and awk installed by default, so the only tre-agrep must be installed. Note that tre-agrep is used instead of grep becaue tre-agrep allows the user to input a maximum number of mismatches when matching regular expressions. We recommend creating a conda environment for using agrepNestAligner with tre-agrep installed, which can be done executing the following commands once conda is installed on your system:
```
conda create -n agrepNestAligner_env
conda activate agrepNestAligner_env
conda install tsnyder::tre
```
To deactivate the agrepNestAligner_env conda environement, run:
```
conda deactivate
```
For instructions on installing conda on your system, see [https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html).

<a name="usage"></a>
## 3. Usage

<a name="build-ref-db-index"></a>
## 3.1. Build reference database index

<a name="run-aligner"></a>
## 3.2. Run agrepNestAligner



