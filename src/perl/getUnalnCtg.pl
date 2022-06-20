#!/usr/bin/perl
#Created by Hu Zhiqiang, 2014-9-5
##Modefied by Duan Zhongqu, 2018-11-27
##Extract both the fully unaligned contigs and partially unaligned contigs.
##Extract the coordinate of partially unaligned contigs locate in reference genome.

use strict;
use warnings;
use Getopt::Std;
use vars qw($opt_h);
getopts("h");

my $usage="\nUsage: $0 [options] <contig_file> <unaligned_info_file> <coords_file> <output_prefix> <prefix>

$0 is used to collect both fully unaligned contigs and partially unaligned contigs, and 
collect the coords of the partially unaligned contigs.

Necessary input description:

  contig_file             <string>    Assembled contig fasta file.

  unaligned_info_file     <string>    File including the info of unaligned contigs.

  coords_file             <string>    File including the coords of contigs.

  output_prefix           <string>    The prefix of outfiles.

  prefix                  <string>    A prefix added to the name of each contig. This is used
                                      to mark which sample the contigs are from.

Options:
     -h                               Print this usage page.

";

die $usage if @ARGV!=5;
die $usage if defined($opt_h);
my ($contig_file,$info_file,$coords_file,$output_prefix,$prefix)=@ARGV;

#Check input file existence
die("Error01: Cannot find $contig_file\n") unless(-e $contig_file);
die("Error02: Cannot find $info_file\n") unless(-e $info_file);
die("Error02: Cannot find $coords_file\n") unless(-e $coords_file);

#Define the output file 
my $full_unalign_file=$output_prefix.".fully.contig";
my $part_unalign_file=$output_prefix.".partially.contig";
my $part_coords_file=$output_prefix.".partially.coords";

#Check existence of output file
print STDERR "Warning: $full_unalign_file file exists. Overwrite.\n" if -e $full_unalign_file;
print STDERR "Warning: $part_unalign_file file exists. Overwrite.\n" if -e $part_unalign_file;
print STDERR "Warning: $part_coords_file file exists. Overwrite.\n" if -e $part_coords_file;

#read in unaligned info file and collect the fully unaligned contig names and the partially unaligned contig name.
my %full_unalign_names;
my %part_unalign_names;
open(IN,$info_file)||die("Error05: cannor read $info_file.\n");
while(my $line=<IN>){
    chomp $line;
    my @string=split "\t",$line;
    if($string[3]=~/^full$/){
        $full_unalign_names{$string[0]}=0;
    }
    elsif($string[3]=~/^partial$/){
        $part_unalign_names{$string[0]}=0; 
    }
}

#collect unaligned contigs from contig file
open(FULL,">$full_unalign_file") || die("Error04: Cannot write $full_unalign_file\n");
open(PART,">$part_unalign_file") || die("Error04: Cannot write $part_unalign_file\n");
if($contig_file=~/\.gz$/){
    open(CONTIG,"zcat $contig_file |") || die("Error05: Cannot read $contig_file\n");
}
else{
    open(CONTIG,$contig_file) || die("Error05: Cannot read $contig_file\n");
}
my $flag=0;
while(my $line=<CONTIG>){
    if($line=~/^>(.+)$/){
	my $m=$1;
	$m=~s/\s+/_/g;
	if(defined($full_unalign_names{$m})){
	    $flag=1;
	    $full_unalign_names{$m}=1;
	    print FULL ">$prefix:$m\n";
	}
        elsif(defined($part_unalign_names{$m})){
            $flag=2;
            $part_unalign_names{$m}=1;
            print PART ">$prefix:$m\n";
        }
	else{
	    $flag=0;
	}
    }
    else{
	print FULL $line if $flag==1;
        print PART $line if $flag==2;
    }
}
close CONTIG;
close FULL;
close PART;

#Examine if all fully unaligned contigs are extracted
foreach my $key1 (keys(%full_unalign_names)){
    print STDERR "WARNING: Cannot find $key1 in $full_unalign_file\n" if $full_unalign_names{$key1}==0;
}

#Examine if all partially unaligned contigs are extracted
foreach my $key2 (keys(%part_unalign_names)){
    print STDERR "WARNING: Cannot find $key2 in $part_unalign_file\n" if $part_unalign_names{$key2}==0;
}

#Collect the coords of partially unaligned contigs from coords file.
open(IN,$coords_file)||die("Error05: Cannot read $coords_file");
open(OUT,">$part_coords_file")||die("Error04: Cannot write $part_coords_file");
print OUT "Query\tRef\tQuery.start\tQuery.end\tRef.start\tRef.end\tQuery.len\tRef.len\tIdentity";
readline IN;
readline IN;
while(my $line=<IN>){
    chomp $line;
    my @string=split /\s+/,$line;
    if(exists($part_unalign_names{$string[12]})){
        $part_unalign_names{$string[12]}=0;
        print OUT $prefix.":".$string[12]."\t".$string[11]."\t".$string[3]."\t".$string[4]."\t".$string[0]."\t".$string[1]."\t".$string[7]."\t".$string[6]."\t".$string[9]."\n";
    }
}
close IN;
close OUT;

#Examine if all the partially unaligned contigs coords are extracted
foreach my $key3 (keys(%part_unalign_names)){
    print STDERR "WARNING: Cannot find $key3 in $part_unalign_file\n" if $part_unalign_names{$key3}==1;
}

