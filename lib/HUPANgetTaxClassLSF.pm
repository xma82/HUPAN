#!/usr/bin/perl
#Created by Duan Zhongqu at 2018-10-31.
package getTaxClass;

sub getTaxClass{
    use strict;
    use warnings;
    use Getopt::Std;
    use vars qw($opt_h);
    getopts("h");
    
    my $usage="\nUsage: hupan getTaxClass [options] <blast_file> <accession2taxid_file> <output_directory>

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
#************** Might be modified for different task submission system *******************
    my $job_out=$out_dir."job";       
    mkdir($job_out);
    my $script_out=$job_out."/scripts"; #job script directory
    mkdir($script_out);
    my $stderr_out=$job_out."/err";     #stdout directory
    mkdir($stderr_out);
    my $stdout_out=$job_out."/out";     #sdterr directory
    mkdir($stdout_out);
##*****************************************************************************************
    
#generate and submit job script
#************** Might be modified for different task submission system *******************
    my $job_file=$script_out."/Taxclass.slurm";   #script_file
    my $err_file=$stderr_out."/Taxclass.err";   #stderr_output_file
    my $out_file=$stdout_out."/Taxclass.out";   #stdout_output_file
    #create job script
    open(JOB,">$job_file")||die("Error05: Unable to create job file: $job_file\n");
    print JOB "\#!/bin/bash\n";
    print JOB "\#BSUB --job-name=Taxclass\n";              #job name
    print JOB "\#BSUB --output=$out_file\n";               #stdout
    print JOB "\#BSUB --error=$err_file\n";               #stderr
    print JOB "$com\n";                              #commands
    close JOB;
    system("bsub $job_file");                       #submit job
#*****************************************************************************************

}
1;
