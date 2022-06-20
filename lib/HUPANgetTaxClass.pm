#!/usr/bin/perl
#Created by Duan Zhongqu at 2018-10-31.
package getTaxClass;

sub getTaxClass{
    use strict;
    use warnings;
    use Getopt::Std;
    use vars qw($opt_h);
    getopts("h");
    
    my $usage="\nUsage: hupan getTaxClass [options] <blast_file> <info_dir> <output_directory>

hupan getTaxClass is used to obtain the taxonomic classification of sequence from blast result.

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
    
#check existense of output directory
    if(-e $out_dir){
        die("Error: output directory \"$out_dir\" already exists.\nTo avoid overwriting of existing files, we kindly request that the \noutput directory should not exist.\n");
    }
    
#adjust directory names and create output directory
    $out_dir.="/" unless($out_dir=~/\/$/);
    mkdir($out_dir); 

#detect perl script to get taxonomic classification
    my $execp="getTaxClass.pl";
    my @path=split /:/,$ENV{PATH};
    my $fpflag=0;
    foreach my $p (@path){
        $p.="/".$execp;
        if(-e $p && -x $p){
            $fpflag=1;
            last;
        }
    }
    die("Executable getTaxClass.pl cannot be found in your PATH!\n") unless($fpflag);

    my $com="$execp $blast_file $info_dir $out_dir";
    system($com);
}
1;
