# SRD-RE (Spatially Resolved Detection of RNA Editing)

The framework SRD-RE (Spatially Resolved Detection of RNA Editing) was developed to identify RNA editing events in spatial RNA sequencing data. To eliminate potential genomic single nucleotide polymorphisms (SNPs), a curated catalog of known A-to-I RNA editing events was utilized. For each spot, supervised RNA editing detection was performed using the mapped BAM (Binary Alignment Map) file, which includes aligned sequencing reads and spatial coordinates. The analysis excluded PCR duplicate reads and reads aligned to multiple loci. In summary, SRD-RE measured the frequency of A-to-G mismatches at each RNA editing site across spots, enabling in situ visualization of RNA editing events.

![image](https://github.com/user-attachments/assets/336e7f97-03c7-4623-9b4b-b156d92b2650)


## Requirements

- Samtools
- Perl


## Usage

**We have tested our code on two widely-used spatial transcriptomics platforms, Stereo-seq and Visium.**

SRD-RE requires the following data types as input:
- Aligned sequencing reads in BAM format must be sorted by their leftmost coordinates.
- A file containing known RNA editing must include at least three columns (Chromosome, Coordinate, and Reference Base) and must be a tab-delimited file.
```
Chromosome   Coordinate  RefBase
chr1    10098541      A
chr1    10105739      A
chr1    10105754      A
chr1    10106540      A
```
- For Visium, a barcode-to-slide coordinate file with three columns (barcode, X, and Y coordinates) must be provided.

```
AAACAACGAATAGTTC        17      1
AAACAAGTATCTCCCA        103     51
AAACAATCTACTAGCA        44      4
AAACACCAATAACTGC        20      60
AAACAGAGCGACTCCT        95      15
AAACAGCTTTCAGAAG        10      44
```

#### For Stereo-seq:

#### Step 1. To remove PCR duplicate reads and reads aligned to multiple loci
   
```
perl Stereo-seq/rmDup.pl -inBam <input.bam> -outBam <output.bam> -samtools samtools

optional arguments:

   -inBam <input.bam>: The input BAM file. Sorted BAM file with alignments ordered by leftmost coordinates is required as input.
   
   -outBam <output.bam>: The output BAM file after removing duplicates and multi-mapped reads.
   
   -samtools samtools: The path to the samtools executable.
```
   
#### Step 2. Supervised detection of RNA editing 

```   
perl Stereo-seq/REcallingSt.pl -dataset dataset -bam <output.bam> -suffix suffix -outdir outdir -samtools samtools -phred phred -qual_cutoff qual_cutoff

optional arguments:

   -dataset dataset: The path to the dataset (Known A-to-I RNA editing, e.g. Dataset/REDIportalV2.0_Mouse_mm10.txt.gz)

   -bam <output.bam>: The input BAM file (output from the previous step).

   -suffix suffix: The suffix of the input file. [Default: bam]

   -outdir outdir: The output directory for results.

   -samtools samtools: The path to the samtools executable.

   -phred phred: The Phred quality score encoding. [Default: 33]

   -qual_cutoff qual_cutoff: The quality cutoff for base calling. [Default: 20]
```


#### The output of the results includes a base count matrix, which is stored in TSV format.

```
For example,

| 53801,56730 | chrX | 115260153 | A | 18 | 2 |

Column Descriptions:

   1. X,Y: X and Y denote the spatial coordinates of the capture locations on the spatial transcriptomics array.

   2. Chromosome: Chromosome identifier, chrX indicates the locus is on the X chromosome.

   3. Coordinate: Genomic coordinate, 115260153 specifies the exact position on the X chromosome.

   4. Reference Base: Reference genome base, A stands for Adenosine.

   5. Total Reads: Total sequencing depth, 18 indicates there are 18 sequencing reads at this locus.

   6. Edited Reads: Edited reads, 2 indicates that 2 out of 18 reads show editing events different from the reference base.
```

#### For Visium:

#### Step 1. To remove PCR duplicate reads and reads aligned to multiple loci
   
```
perl Visium/rmDupStVisiumIllumina.pl -inBam <input.bam> -outBam <output.bam> -samtools samtools

optional arguments:

   -inBam <input.bam>: The input BAM file. Sorted BAM file with alignments ordered by leftmost coordinates is required as input. 

   -outBam <output.bam>: The output BAM file after removing duplicates and multi-mapped reads.

   -samtools samtools: The path to the samtools executable.
```

#### Step 2. Supervised detection of RNA editing 

```
perl Visium/REcallingStVisiumIllumina.pl -barcode2slide barcode2slide -dataset dataset -bam <output.bam> -suffix suffix -outdir outdir -samtools samtools -phred phred -qual_cutoff qual_cutoff

optional arguments:

   -barcode2slide barcode2slide: The path to the barcode-to-slide coordinates file, e.g. Visium/barcodes/visium-v1_coordinates.txt

   -dataset dataset: The path to the dataset (Known A-to-I RNA editing, e.g. Dataset/REDIportalV2.0_Mouse_mm10.txt.gz)

   -bam <output.bam>: The input BAM file (output from the previous step).

   -suffix suffix: The suffix of the input file. [Default: bam]

   -outdir outdir: The output directory for results.

   -samtools samtools: The path to the samtools executable.

   -phred phred: The Phred quality score encoding. [Default: 33]

   -qual_cutoff qual_cutoff: The quality cutoff for base calling. [Default: 20]
```
[NOTE]
   
   Ensure that the paths to the Perl scripts and the samtools executable are correct. Replace <input.bam>, <output.bam>, dataset, outdir, and other placeholders with actual values specific to your data and environment. The -phred 33 option assumes that the quality scores are encoded using the Illumina 1.8+ format. If your data uses a different encoding, adjust this parameter accordingly. The -qual_cutoff 20 option sets a quality threshold for base calling, which can be adjusted based on the quality of your sequencing data.
  
## Citation

## Contact

If you have any comments or suggestions, please raise an issue or contact me:

Jinrong Huang (huangjinrong@genomics.cn)

## License

**SRD-RE is free for academic use only.**



   
   

