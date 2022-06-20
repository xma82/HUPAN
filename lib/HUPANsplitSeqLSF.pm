#!/usr/perl/bin
#Created by Duan Zhongqu at 2018-11-11.
package splitSeq;

sub splitSeq{
    use strict;
    use warnings;
    use Getopt::Std;
    use vars qw($opt_h $opt_m);
    getopts("hm:");
    my $usage="\nUsage: hupanSLF splitSeq [options] <sequence_file> output_directory

hupanSLF splitSeq is used to split sequence file into multiple small file.

Necessary input description:

  <sequence_file>           <string>     The sequence file.

  <output_directory>        <string>     The output directory. 

Options:
    -h                                   Print this Usage.
    
    -m                      <int>        The size of small file.
                                         Default: 5000000 bp.

";

   die $usage if @ARGV<2;
   die $usage if defined $opt_h;
   my ($seq_file,$out_dir)=@ARGV;

#check existense of output directory
    if(-e $out_dir){
        die("Error: output directory \"$out_dir\" already exists. To avoid overwriting of existing files, we kindly request that the output directory should not exist.\n");
    }

#adjust directory names and create output directory
    $out_dir.="/" unless($out_dir=~/\/$/);
    mkdir($out_dir);
    
#get the size of small file
    my $file_size=5000000;
    $file_size=$opt_m if defined $opt_m;

#read the sequence file and split into samll file
    open(IN,$seq_file)||die("Error9: cannot read the file $seq_file.\n");
    my $count=1;
    my $split_out_dir=$out_dir."part".$count."/";
    mkdir($split_out_dir);
    my $length=0;
    my $seq;
    my $name="";
    while(my $line=<IN>){
        chomp $line;
        if($line=~/^>/){
            if($name eq ""){
                $name=$line;
                $seq="";
            }
            else{
                if($length>=$file_size){
                    $count+=1;
                    $length=0;
                    $split_out_dir=$out_dir."part".$count."/";
                    mkdir($split_out_dir);
                }
                my $split_seq_file=$split_out_dir."part".$count.".fa";
                open(OUT,">>$split_seq_file")||die("Error10: cannot write the file: $split_seq_file.\n");
                print OUT $name."\n".$seq."\n";
                close OUT;
                $name=$line;
                $seq="";
            }
        }
        else{
            $seq=$seq.$line;
            $length+=length($line);
            if(eof){
                my $split_seq_file=$split_out_dir."part".$count.".fa";
                open(OUT,">>$split_seq_file")||die("Error10: cannot write the file: $split_seq_file.\n");
                print OUT $name."\n".$seq."\n";
                close OUT;
            }   
        }
    }
}
1;
