# SRD-RE

The framework SRD-RE (Spatially Resolved Detection of RNA Editing) was developed to identify RNA editing events in spatial RNA sequencing data. To eliminate potential genomic single nucleotide polymorphisms (SNPs), a curated catalog of known A-to-I RNA editing events was utilized. For each spot, supervised RNA editing detection was performed using the mapped BAM (Binary Alignment Map) file, which includes aligned sequencing reads and spatial coordinates. The analysis excluded PCR duplicate reads and reads aligned to multiple loci. In summary, SRD-RE measured the frequency of A-to-G mismatches at each RNA editing site across spots, enabling in situ visualization of RNA editing events. Sorted BAM file with alignments ordered by leftmost coordinates is required as input. We have tested our code on two widely-used spatial transcriptomics platforms, Stereo-seq and Visium.

![image](https://github.com/user-attachments/assets/a2e7c5a6-df2d-4d0d-96ce-c00f174e0ab7)

## Requirements

#### Samtools
#### Perl


## Usage

For Stereo-seq

1. To remove PCR duplicate reads and reads aligned to multiple loci
   
   perl Stereo-seq/rmDup.pl -inBam <input.bam> -outBam <output.bam> -samtools samtools

   optional arguments:

   -inBam <input.bam>: Specifies the input BAM file.
   
   -outBam <output.bam>: Specifies the output BAM file after removing duplicates and multi-mapped reads.
   
   -samtools samtools: Specifies the path to the samtools executable.
   
3. Supervised detection of RNA editing 

   perl Stereo-seq/REcallingSt.pl -dataset dataset -bam <output.bam> -suffix bam -outdir outdir -samtools samtools -phred 33 -qual_cutoff 20

   optional arguments:

   -dataset dataset: Specifies the path to the dataset.

   -bam <output.bam>: Specifies the input BAM file (output from the previous step).

   -suffix bam: Specifies the suffix of the input file.

   -outdir outdir: Specifies the output directory for results.

   -samtools samtools: Specifies the path to the samtools executable.

   -phred 33: Specifies the Phred quality score encoding (33 for Illumina 1.8+).

   -qual_cutoff 20: Specifies the quality cutoff for base calling.

For Visium

1. To remove PCR duplicate reads and reads aligned to multiple loci
   
   perl Visium/rmDupStVisiumIllumina.pl -inBam <input.bam> -outBam <output.bam> -samtools samtools

   optional arguments:

   -inBam <input.bam>: Specifies the input BAM file.

   -outBam <output.bam>: Specifies the output BAM file after removing duplicates and multi-mapped reads.

   -samtools samtools: Specifies the path to the samtools executable.
   
3. Supervised detection of RNA editing 

   perl Visium/REcallingStVisiumIllumina.pl -barcode2slide Visium/barcodes/visium-v1_coordinates.txt -dataset dataset -bam <output.bam> -suffix bam -outdir outdir -samtools samtools -phred 33 -qual_cutoff 20

   optional arguments:

   -barcode2slide Visium/barcodes/visium-v1_coordinates.txt: Specifies the path to the barcode-to-slide coordinates file.

   -dataset dataset: Specifies the path to the dataset.

   -bam <output.bam>: Specifies the input BAM file (output from the previous step).

   -suffix bam: Specifies the suffix of the input file.

   -outdir outdir: Specifies the output directory for results.

   -samtools samtools: Specifies the path to the samtools executable.

   -phred 33: Specifies the Phred quality score encoding (33 for Illumina 1.8+).

   -qual_cutoff 20: Specifies the quality cutoff for base calling.

   Notes:
   
   Ensure that the paths to the Perl scripts (rmDup.pl, REcallingSt.pl, rmDupStVisiumIllumina.pl, REcallingStVisiumIllumina.pl) and the samtools executable are correct.

   Replace <input.bam>, <output.bam>, dataset, outdir, and other placeholders with actual values specific to your data and environment.

   The -phred 33 option assumes that the quality scores are encoded using the Illumina 1.8+ format. If your data uses a different encoding, adjust this parameter accordingly.

   The -qual_cutoff 20 option sets a quality threshold for base calling, which can be adjusted based on the quality of your sequencing data.
  
## Citation

   
   

