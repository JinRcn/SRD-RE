#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# 10x genomics visium
# Illumina sequencing

my ($inBam,$outBam,$samtools);

GetOptions(
	"inBam=s" => \$inBam,
	"outBam=s" => \$outBam,
	"samtools=s" => \$samtools,
);

$samtools ||="samtools";

my %hash=();
my $PreviousSEQ;

open OT,"| $samtools view -b -S ->$outBam" or die $!;
open IN,"$samtools view -h $inBam|" or die $!;
while (<IN>){
	chomp;
	if (/^@/){
		print OT "$_\n";
		next;
	}
## spaceranger-2.1.0 V1_Adult_Mouse_Brain
	#A00984:21:HMKLFDMXX:2:1486:29487:9283   0       chr6    3050464 255     8M150693N104M8S *       0       0       GCCGCGATGCGAGTCACCGCCCGTCCCCGCCCCTTTCCACTCGGCGCCCCCACGAATCTCATAGCTGATTGTCCCGCGGGGCCCCAAGCGTTTAAATTGAAAAAATTAGAGTTTTCAAAG        F:F:FFF,FF,F,,,F,F:FFF:F,FFF,:FF::,,F,,F,F,,F:FFFFF,FF,,,:,,:,F,,,,F,:FFFFF,F,FFFFFF,FF,F:FFFF:,FF,:FFFFF:FF:F:,,FFFFFF:        NH:i:1  HI:i:1  AS:i:80 nM:i:10 RG:Z:V1_Adult_Mouse_Brain:0:1:HMKLFDMXX:2       RE:A:I  xf:i:0  CR:Z:ACTCAAGTGCAAGGCT   CY:Z:FFFFFFFFFFFFFFFF   CB:Z:ACTCAAGTGCAAGGCT-1 UR:Z:GAATTTGCTGTC       UY:Z:FFFFFFFFFFFF       UB:Z:GAATTTGCTGTC
	my @t=split /\t/;
	next unless ($_=~/\s+NH:i:1\s+/);
	my $FLAG=$t[1];
	next unless $FLAG < 256;
	# 0x100   256  SECONDARY      secondary alignment
	# 0x200   512  QCFAIL         not passing quality controls or other filters
	# 0x400  1024  DUP            PCR or optical duplicate
	# 0x800  2048  SUPPLEMENTARY  supplementary alignment
	my $SEQ=$t[9];
	my $UB;
	if ($_=~/\s+(UB:Z:\w+)/){$UB=$1;}
	else {next;}
	my $CB;
	if ($_=~/\s+(CB:Z:\w+-\d+)/){$CB=$1;}
	else {next;}
	my $seqInfo="$SEQ\t$UB\t$CB";

	if (!defined $PreviousSEQ){
		$PreviousSEQ=$SEQ;
		$hash{$seqInfo}++;
		print OT "$_\n";
	}
	else {
		if ($SEQ eq $PreviousSEQ){
			if (exists $hash{$seqInfo}){
				$hash{$seqInfo}++;
				next;
			}
			else {
				$hash{$seqInfo}++;
				print OT "$_\n";
			}
		}
		else {
			%hash=();
			$PreviousSEQ=$SEQ;
			$hash{$seqInfo}++;
			print OT "$_\n";
		}
	}
}
close IN;
close OT;
exit;
