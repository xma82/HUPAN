#!/usr/bin/perl
#Created by Duan Zhongqu at 2018-10-31.
#Revised by Duan Zhongqu at 2019-03-06.

##############################################################################################
#             This script firstly extracts all ACCESSION ID from blast result,               #
#             and then obtains the Taxonomy ID by the file: nucl_gb.accession2taxid,         #
#             finnaly, the lineage information were obtain according to rankedlineage.dmp    #
##############################################################################################

use strict;
use warnings;
use Getopt::Std;
use vars qw($opt_h);
getopts("h");
    
my $usage="\nUsage: $0 [options] <blast_file> <info_dir> <output_directory>

$0 is used to obtain the taxonomic classification of each sequence from blast result.

Necessary input description:
  
    <blast_file>            <string>          The blast result of sequences aligning to nt database.

    <info_dir>              <string>          The directory should contain two files:
                                              1. nucl_gb.accession2taxid, which is available in
                                              ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/;
                                              2. rankedlineage.dmp, which is available in
                                              https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/.
 
    <output_directory>      <string>          The output directory.

Options:
  
    -h                                        Print this usage.

";
  
die $usage if @ARGV!=3;
die $usage if $opt_h;
my ($blast_file,$info_dir,$out_dir)=@ARGV;

die("Error01: Cannot find $blast_file\n") unless(-e $blast_file);
die("Error01: Cannot find $info_dir\n") unless(-e $info_dir);
unless($info_dir=~/\/$/){
    $info_dir.="/";
}
unless($out_dir=~/\/$/){
    $info_dir.="/";
}
my $accession2taxid=$info_dir."nucl_gb.accession2taxid";
my $rankedlineage=$info_dir."rankedlineage.dmp";

unless(-e $accession2taxid){
    die("Error01: Cannot find the file: nucl_gb.accession2taxid in the $info_dir,\nplease download from the website: ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/.")
}

unless(-e $rankedlineage){
    die("Error01: Cannot find the file: rankedlineage.dmp in the $info_dir,\nplease download from the website: https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/.")
}

#get the accession id of each alignment
open(IN,$blast_file)||die("Error9: cannot read the file: $blast_file!\n");
my %accession;
while(my $line=<IN>){
chomp $line;
next if $line=~/^#/;
my @string=split "\t",$line;
my @accession_version=split(/\./,$string[1]);
    $accession{$accession_version[0]}=$string[1];
}
close IN;
my $len1=keys %accession;
my $log_file=$out_dir."job.log";
open(LOG,">$log_file")||die("Error10: cannot write the file $log_file.\n");
print LOG "There are $len1 accession in the blast file.\n";

#get the related taxonomic id of accession id from accession2taxid file.
open(FILE1,$accession2taxid)||die("Error9: cannot read the file $accession2taxid!\n");
my %acc_tax;
while(my $line=<FILE1>){
    chomp $line;
    my @string=split "\t",$line;
    if(exists $accession{$string[0]}){
        $acc_tax{$string[0]}=$string[2]
    }
}
close FILE1;
my $len2=keys %acc_tax;
print LOG "\tOf these, $len2 accessiones could be found in the $accession2taxid.\n";

my $html_dir=$out_dir."html/";
mkdir($html_dir);

#obtain the taxonomix id of some accession id due to updating accession2taxid file.    
if($len1!=$len2){
    my @acc_keys=keys %accession;
    my @non=grep {!$acc_tax{$_}} @acc_keys;
    my $len3=@non;
    print LOG "\tIn total $len3 accessions have been removed in the file: $accession2taxid , and we will search them from NCBI.\n";
    foreach my $line (@non){
        my $html_file=$html_dir.$line.".html";
        system("wget https://www.ncbi.nlm.nih.gov/nuccore/$line -O $html_file");
        open(HTML,$html_file)||die("error with opening $html_file\n");
        while(<HTML>){
            if($_ =~ /ORGANISM=(\d+)&amp;/){
                my $tax_id=$1;
                $acc_tax{$line}=$tax_id;
            }
        } 
        close HTML;
    }
}

#obtain taxonomic classification of each taxonomic id    
my %taxid;
while((my $key, my $value)=each %acc_tax){
    $taxid{$value}=1;
}
my $len4=keys %taxid;
my $taxid_file=$out_dir."taxid.txt";
print LOG "\nThere are $len4 taxid could be found.\n";
open(TAX,">$taxid_file")||die("Error10: cannot write the file: $taxid_file.\n");
while((my $key, my $value)=each %taxid){
    print TAX $key."\n";
}
close TAX;

my %source;
open(IN,$rankedlineage)||die("Cannot read the file: $rankedlineage.\n");
while(my $line=<IN>){
    chomp $line;
    my @string=split /\t\|\t/,$line;
    if(exists($taxid{$string[0]})){
        $string[9]=~ s/\t|$//;
        $source{$string[0]}.="superkingdom:".$string[9]."; ";
        $source{$string[0]}.="kingdom:".$string[8]."; ";
        $source{$string[0]}.="phylum:".$string[7]."; ";
        $source{$string[0]}.="class:".$string[6]."; ";
        $source{$string[0]}.="order:".$string[5]."; ";
        $source{$string[0]}.="family:".$string[4]."; ";
        $source{$string[0]}.="genus:".$string[3]."; ";
        $source{$string[0]}.="species:".$string[2].".";
    }
}
close IN;

my $len5=keys %source;
my $taxid_name_file=$out_dir."taxid.name";
print LOG "There are $len5 taxid and name could be found.\n";
open(NAME,">$taxid_name_file")||die("Error10: cannot write the file: $taxid_name_file.\n");
while((my $key, my $value)=each %source){
    print NAME $key."\t".$value."\n";
}
    
my $out_file=$out_dir."accession.name";
open(OUT,">$out_file")||die("Error10: cannot write the table: $out_file.\n");
print OUT "accesion\taccession.version\ttaxid\tsource\n";
while((my $key, my $value)=each %accession){
    #print $key."\n";
    my $taxonomy=$acc_tax{$key};
    my $records;
    if(exists $source{$taxonomy}){
        $records=$source{$taxonomy};
    }
    else{
        $records="Unclassified";    
    }
    print OUT $key."\t".$value."\t".$taxonomy."\t".$records."\n";
}
close OUT;
close LOG;
