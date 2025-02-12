# SRD-RE

The framework SRD-RE (Spatially Resolved Detection of RNA Editing) was developed to identify RNA editing events in spatial RNA sequencing data. To eliminate potential genomic single nucleotide polymorphisms (SNPs), a curated catalog of known A-to-I RNA editing events was utilized. For each spot, supervised RNA editing detection was performed using the mapped BAM (Binary Alignment Map) file, which includes aligned sequencing reads and spatial coordinates. The analysis excluded PCR duplicate reads and reads aligned to multiple loci. In summary, SRD-RE measured the frequency of A-to-G mismatches at each RNA editing site across spots, enabling in situ visualization of RNA editing events.

![image](https://github.com/user-attachments/assets/a2e7c5a6-df2d-4d0d-96ce-c00f174e0ab7)

## Requirements

#### Samtools
#### Perl

## Usage

1. To remove PCR duplicate reads and reads aligned to multiple loci
   
   Sorted BAM files with alignments by leftmost coordinates were required.

   perl rmDup.pl -inBam <input.bam> -outBam <output.bam> -samtools samtools
   
3. Supervised RNA editing detection

