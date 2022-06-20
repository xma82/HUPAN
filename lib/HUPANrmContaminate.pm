#!/usr/bin/perl
#Created by Duan Zhongqu, 2018-10-22
package rmCTM;

sub rmContaminate{
    use strict;
    use warnings;
    use Getopt::Std;
    use vars qw($opt_h $opt_l $opt_i);
    getopts("hl:i:");
    my $usage="\nUsage: hupan rmCtm [options] <sequence_file> <blast_file> <accession_file> <output_directory>

hupan rmCtm is used to detect and discard the potentail contaminated sequence.

Necessary input description:

  sequence_file        <string>      The sequence file.
  
  blast_file           <string>      The blast result of sequence file.

  accession_file       <string>      The accession file.

  output_directory     <string>      Both final output files and intermediate results 
                                     will be found in this directory. To avoid 
                                     overwriting of existing files, we kindly request
                                     that the output_directory should not exist. It is
                                     to say, this directory will be created by the 
                                     script itself.

Options:

     -h                              Print this usage page.
     
     -l                <int>         The local alignment length. (default: 100 bp)

     -i                <int>         The local alignment identity. (default: 90%)

";

   die $usage if @ARGV!=4;
   die $usage if defined($opt_h); 
   my ($seq_file,$blast_file,$accession_file,$out_dir)=@ARGV;

#check existence of output directory
   if(-e $out_dir){
        die("Error: output directory \"$out_dir\" already exists.\nTo avoid overwriting of existing files, we kindly request that the \noutput directory should not exist.\n");
    }

#adjust directory names and create output directory
    $out_dir.="/" unless($out_dir=~/\/$/);
    mkdir($out_dir);
    my $log_file=$out_dir."RemoveContaminate.log";
    
#get the minimum alignment length and alignment identity
    my $min_length=100;
    $min_length=$opt_l if defined $opt_l;
    my $min_identity=90;
    $min_identity=$opt_i if defined $opt_i; 

#detect perl script to get taxonomic classification
    my $execp="rmCtm.pl";
    my @path=split /:/,$ENV{PATH};
    my $fpflag=0;
    foreach my $p (@path){
        $p.="/".$execp;
        if(-e $p && -x $p){
            $fpflag=1;
            last;
        }
    }
    die("Executable rmCtm.pl cannot be found in your PATH!\n") unless($fpflag);

    my $com="$execp $seq_file $blast_file $accession_file $out_dir $min_length $min_identity";
    system($com);
}
1;
