#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# A-to-I RNA editing calling based on BAM created using ST
# Jinrong Huang

my ($dataset);
my ($bam,$suffix);
my ($outdir,$samtools);
my ($phred,$qual_cutoff);

GetOptions(
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

my %dataset;	# known RNA editing sites

if($dataset=~/\.gz$/){open IN,"gunzip -cd <$dataset|" or die $!;}else{open IN,"<$dataset" or die $!;}
while (<IN>){
	# Chromosome_ID   Coordinate      Ref_base        CodonChange     AminoAcidChange Gene    Annotation      Detailed information    Repeat
	# 1       25274   A       -       -       ENSSSCG00000027257:PSMB1        intronic        ENSSSCG00000027257:PSMB1:intronic       SINE/tRNA
	# 1       4846284 T       -       -       ENSSSCG00000004029:QKI  intronic        ENSSSCG00000004029:QKI:intronic SINE/tRNA
	chomp;
 	next if $.==1;
	my ($chr,$pos,$ref)=(split /\t/)[0,1,2];
	$dataset{"$chr\t$pos"}=$ref;
}
close IN;

my $name=(split /\//,$bam)[-1];
$name=~s/\.$suffix$//;

my %sites;
open IN,"$samtools view $bam|" or die $!;
while (<IN>){
	chomp;
	my ($CHR,$POS,$CIGAR,$SEQ,$QUAL)=(split /\t/)[2,3,5,9,10];
	# Cx:i:22480 Cy:i:18290
	my $Cx=$1 if (/Cx:i:(\d+)/);
	my $Cy=$1 if (/Cy:i:(\d+)/);
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
		else {die "Incorrect format of CIGAR. Make sure the input is bam format!\n"}
	}
}
close IN;

my $sam2base="$outdir/$name.sam2base.gz";
if($sam2base=~/\.gz$/){open OT,"|gzip >$sam2base" or die $!;}else{open OT,">$sam2base" or die $!;}
while (my($k,$v)=each %sites){
#foreach my $k(sort keys %sites){
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
	print OT "$xy\t$chr\t$pos\t$refbase\t$cov\t$alt\n";
}
close IN;
close OT;
exit;
