# SRD-RE

The framework SRD-RE (Spatially Resolved Detection of RNA Editing) was developed to identify RNA editing events in spatial RNA sequencing data. To eliminate potential genomic single nucleotide polymorphisms (SNPs), a curated catalog of known A-to-I RNA editing events was utilized. For each spot, supervised RNA editing detection was performed using the mapped BAM (Binary Alignment Map) file, which includes aligned sequencing reads and spatial coordinates. The analysis excluded PCR (Polymerase chain reaction) duplicate reads and reads aligned to multiple loci. In summary, SRD-RE measured the frequency of A-to-G mismatches at each RNA editing site across spots, enabling in situ visualization of RNA editing events.

![pipeline-ing-01-M](https://github.com/user-attachments/assets/ae850d5a-86fe-4dc8-a27d-40f4011af026)



