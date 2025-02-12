#!/usr/bin/perl -w
use strict;
use Getopt::Long;

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
	# FP200007450L1C068R07202771685   0       chr17   18      255     98M2S   *       0       0       CCTCCACACCTGTGGGTGTTTCTCGTTAGGTGGAACGAGAGACTTGAGAAAAGAAAGAAGACACAGAGACAAAGTATAGAGAAAGAAAAGCGCGGGCCCA    FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF    NH:i:1  HI:i:1  AS:i:92 nM:i:2  Cx:i:14741      Cy:i:10055      UR:Z:E5B5C      XF:i:2
	# FP200007450L1C068R07202771686   0       chr17   18      255     98M2S   *       0       0       CCTCCACACCTGTGGGTGTTTCTCGTTAGGTGGAACGAGAGACTTGAGAAAAGAAAGAAGACACAGAGACAAAGTATAGAGAAAGAAAAGCGCGGGCCCA    FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF    NH:i:1  HI:i:1  AS:i:92 nM:i:2  Cx:i:14741      Cy:i:10055      UR:Z:E5B5C      XF:i:2
#	$m++;
	my @t=split /\t/;

	next unless ($_=~/NH:i:1\s+/);

	my $FLAG=$t[1];
	next unless $FLAG < 256;
	# 0x100   256  SECONDARY      secondary alignment
	# 0x200   512  QCFAIL         not passing quality controls or other filters
	# 0x400  1024  DUP            PCR or optical duplicate
	# 0x800  2048  SUPPLEMENTARY  supplementary alignment

	my $SEQ=$t[9];
	my $UR=$1 if ($_=~/\s+(UR:Z:\w+)\s+/);
	my $Cx=$1 if ($_=~/\s+(Cx:i:\d+)\s+/);
	my $Cy=$1 if ($_=~/\s+(Cy:i:\d+)\s+/);
	my $seqInfo="$SEQ\t$UR\t$Cx\t$Cy";

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
