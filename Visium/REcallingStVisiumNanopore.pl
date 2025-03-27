#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# A-to-I RNA editing calling based on BAM created using ST
# 10x genomics visium
# Oxford nanopore sequencing
# Jinrong Huang

my ($barcode2slide);
my ($dataset);
my ($bam,$suffix);
my ($outdir,$samtools);
my ($phred,$qual_cutoff);

GetOptions(
	"barcode2slide=s" => \$barcode2slide,
	"dataset=s" => \$dataset,
	"bam=s" => \$bam,
	"suffix=s" => \$suffix,
	"outdir=s" => \$outdir,
	"samtools=s" => \$samtools,
	"phred=i" => \$phred,
	"qual_cutoff=i" => \$qual_cutoff,
);

$suffix ||="bam";
$samtools ||="samtools";
$phred ||="33";
$qual_cutoff ||="20";

`mkdir -p $outdir` unless (-e $outdir);

# A-to-G
my %hash = (
	"A" => "G",
	"T" => "C",
);

my %barcode2slide;
open IN,"$barcode2slide" or die $!;
while (<IN>){
	chomp;
	my ($barcode,$x,$y)=split /\t/;
	$barcode2slide{$barcode}="$x,$y";
}
close IN;

my %dataset;	# known RNA editing sites

if($dataset=~/\.gz$/){open IN,"gunzip -cd <$dataset|" or die $!;}else{open IN,"<$dataset" or die $!;}
while (<IN>){
	# Region  Position        Ref     Ed      Strand  db      type    dbsnp   repeat  Func.wgEncodeGencodeBasicVM16   Gene.wgEncodeGencodeBasicVM16   GeneDetail.wgEncodeGencodeBasicVM16     ExonicFunc.wgEncodeGencodeBasicVM16     AAChange.wgEncodeGencodeBasicVM16       Func.refGene    Gene.refGene    GeneDetail.refGene      ExonicFunc.refGene      AAChange.refGene        Func.knownGene  Gene.knownGene  GeneDetail.knownGene    ExonicFunc.knownGene    AAChange.knownGene      phastConsElements60way	
	# chr3    80692286        T       C       -       A,R,D   NONREP  -       -/-     exonic  Gria2   nonsynonymous SNV       Gria2:ENSMUST00000075316.9:exon13:c.A2290G:p.R764G,Gria2:ENSMUST00000107745.7:exon13:c.A2290G:p.R764G   exonic  Gria2   nonsynonymous SNV       Gria2:NM_001039195:exon13:c.A2290G:p.R764G,Gria2:NM_001083806:exon13:c.A2290G:p.R764G,Gria2:NM_001357924:exon13:c.A2290G:p.R764G,Gria2:NM_001357927:exon13:c.A2290G:p.R764G,Gria2:NM_013540:exon13:c.A2290G:p.R764G     exonic  Gria2   nonsynonymous SNV       Gria2:uc008pnz.1:exon12:c.A2149G:p.R717G,Gria2:uc008poa.1:exon13:c.A2290G:p.R764G,Gria2:uc008pob.1:exon13:c.A2290G:p.R764G,Gria2:uc008pod.1:exon13:c.A2290G:p.R764G     715;1306
	chomp;
 	next if $.==1;
	my ($chr,$pos,$ref)=(split /\t/)[0,1,2];
	$chr="chr$chr" unless ($chr =~/^chr/);
	$dataset{"$chr\t$pos"}=$ref;
}
close IN;

my $name=(split /\//,$bam)[-1];
$name=~s/\.$suffix$//;

my %sites;
open IN,"$samtools view $bam|" or die $!;
while (<IN>){
	chomp;
	my ($FLAG,$CHR,$POS,$CIGAR,$SEQ,$QUAL)=(split /\t/)[1,2,3,5,9,10];

	next unless $FLAG < 256;
	# 0x100   256  SECONDARY      secondary alignment
	# 0x200   512  QCFAIL         not passing quality controls or other filters
	# 0x400  1024  DUP            PCR or optical duplicate
	# 0x800  2048  SUPPLEMENTARY  supplementary alignment

	$CHR="chr$CHR" unless ($CHR =~/^chr/);
	my $CB=$1 if ($_=~/\s+(BC:Z:\w+)/);
	$CB=~s/^BC:Z://;
	my ($Cx,$Cy);
	if (exists $barcode2slide{$CB}){
		($Cx,$Cy)=(split /,/,$barcode2slide{$CB})[0,1];
	}
	else {die "The spot barcode sequence can not be found in the $barcode2slide!\n"}

	my $coordinate="$Cx,$Cy";
	my @SEQ =split //,$SEQ;
	my @QUAL =split //,$QUAL;
	my @CIGAR=$CIGAR=~/(\d+[A-Z])/g;

	my $refPos=$POS;
	my $seqPos =0;
	for(my $i=0;$i<@CIGAR;$i++){
		if($CIGAR[$i]=~/M/){
			$CIGAR[$i]=~s/M//;
			for (my $j=0;$j<$CIGAR[$i];$j++){
				my $currentPos=$refPos+$j;
				my $index="$CHR\t$currentPos";
				if (exists $dataset{$index}){
					my $I="$coordinate\t$index";
					$sites{$I}{'SEQ'}.= $SEQ[$seqPos];
					$sites{$I}{'QUAL'}.= $QUAL[$seqPos];
				}
				$seqPos++;
			}
			$refPos+=$CIGAR[$i];
		}
		elsif ($CIGAR[$i]=~/D/){
			$CIGAR[$i]=~s/D//;
			$refPos+=$CIGAR[$i];
		}
		elsif ($CIGAR[$i]=~/H/){  # added,Mar13,2024
			$CIGAR[$i]=~s/H//;
			$refPos+=$CIGAR[$i];
		}
		elsif ($CIGAR[$i]=~/I/){
			$CIGAR[$i]=~s/I//;
			$seqPos+=$CIGAR[$i];
		}
		elsif ($CIGAR[$i]=~/N/){
			$CIGAR[$i]=~s/N//;
			$refPos+=$CIGAR[$i];
		}
		elsif ($CIGAR[$i]=~/S/){
			$CIGAR[$i]=~s/S//;
			$seqPos+=$CIGAR[$i];
		}
		else {die "$.\t$_\tIncorrect format of CIGAR. Make sure the input is bam format!\n"}
	}
}
close IN;

my $sam2base="$outdir/$name.sam2base.gz";
if($sam2base=~/\.gz$/){open OT,"|gzip >$sam2base" or die $!;}else{open OT,">$sam2base" or die $!;}
#while (my($k,$v)=each %sites){
foreach my $k(sort keys %sites){
	my ($xy,$chr,$pos)=split /\t/,$k;
	my $index="$chr\t$pos";
	my $seq=$sites{$k}{'SEQ'};
	my $qual=$sites{$k}{'QUAL'};
	print OT "$k\t$dataset{$index}\t$seq\t$qual\n";
}	
close OT;

my $input=$sam2base;
my $output="$outdir/$name.REs.gz";
if($output=~/\.gz$/){open OT,"|gzip >$output" or die $!;}else{open OT,">$output" or die $!;}
if($input=~/\.gz$/){open IN,"gunzip -cd <$input|" or die $!;}else{open IN,"<$input" or die $!;}
while (<IN>){
	# Cx,Cy
	# 41892,23117     chr9    14717230        T       TTTTTTTTTTTTTT  FFFFFFFFFFFFFF
	chomp;
	my ($xy,$chr,$pos,$refbase,$seq,$qual)=split /\t/;
	my @base=split //,$seq;
	my @qual=split //,$qual;
	my ($base_new,$qual_new);
	my $cov=0;
	my ($ref,$alt)=("0","0");
	my $other=0;
	for (my $i=0;$i<@base;$i++){
		my $score=ord($qual[$i])-$phred;
		next if $base[$i] eq "N";
		next if $score < $qual_cutoff;
		if ($base[$i] =~/^$refbase$/i){
			$ref++;
			$cov++;
			$base_new.=$base[$i];
			$qual_new.=$qual[$i];
		}
		elsif ($base[$i] =~/^$hash{$refbase}$/i){
			$alt++;
			$cov++;
			$base_new.=$base[$i];
			$qual_new.=$qual[$i];
		}
		else {
			$other++;
		}
	}
	print OT "$xy\t$chr\t$pos\t$refbase\t$cov\t$alt\n" if ($cov >0);
}
close IN;
close OT;
exit;
