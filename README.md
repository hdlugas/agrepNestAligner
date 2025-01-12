# agrepNestAligner

Alignment algorithm designed specifically for aligning small RNA-sequencing data to database of non-coding RNAs (ncRNAs).

In a database of ncRNAs such as miRbase for example, it is often the case that a hairpin microRNA (miRNA) contains an subsequence equivalent to a mature miRNA (e.g. hsa-mir-12117=GTCTCAGT*GAAGTGGAGCACATCAGTGA*AAGGGTGAACTTAACCTTTCACTGGTGTGCTCCATCTCACTCAGAC contains hsa-miR-12117=GAAGTGGAGCACATCAGTGA). If a small RNA-sequencing read is exactly equivalent to a mature miRNA such as hsa-miR-12117 after the unique molecular identifier (UMI) is removed and either BWA or Bowtie is used to align the given read to a database containing both the mature and hairpin miRNA, then the read will often be aligned to the hairpin miRNA even though the read exactly matches the mature miRNA. This is the case because BWA, Bowtie, and other common aligners are designed to align reads to the human genome where reference sequences are not exact subsequences of each other (e.g. chromosome 13 is not an exact subsequence of chromosome 17). The alignment tool agrepNestAligner is a more biologically-relevant aligner specifically for aligning small RNA-sequencing data to a database of ncRNAs which accounts for the nuances of nested reference sequences.

Common bioinformatics workflows which process small RNA-sequencing data typically involve using an aligner such as Burrows-Wheeler Aligner (BWA) or Bowtie to align reads to a database of non-coding RNAs (ncRNAs) such as miRbase. 



