#!/usr/bin/perl
#Created by Duan Zhongqu, 2018-10-24
package genePre;

sub genePre{
    use strict;
    use warnings;
    use Getopt::Std;
    use vars qw($opt_h $opt_t);
    getopts("ht:");
    my $usage="\nUsage: hupan genePre [options] <data_directory> <output_directory> <maker_config> <maker_directory>

hupan genePre is used to ab initio gene predict combining with RNA and protein evidence.

Necessary input description:

  <data_directory>          <string>     The directory include one or multiple subdirectories,
                                         named by part1, part2, etc. In each sub-directory, 
                                         the file (*.fa) of non-reference sequences should exists.


  <output_directory>        <string>     The output directory.
  
  <maker_config>            <string>     The config file used in maker.

  <maker_directory>         <string>     The directory maker locates.

Options:
  
          -h                             Print this usage.

          -t                <string>     Thread number.

";

    die $usage if @ARGV!=4;
    die $usage if $opt_h;
    my ($data_dir,$out_dir,$maker_ctg,$maker_dir)=@ARGV;

#check existense of output directory
#    if(-e $out_dir){
#        die("Error: output directory \"$out_dir\" already exists.\nTo avoid overwriting of existing files, we kindly request that the \noutput directory should not exist.\n");
#    }

#adjust directory names and create output directory
    $data_dir.="/" unless($data_dir=~/\/$/);
    $out_dir.="/" unless($out_dir=~/\/$/);
    $maker_dir.="/" unless($maker_dir=~/\/$/);
    mkdir($out_dir);

    my $thread_num=1;
    $thread_num=$opt_t if defined $opt_t;

    my $maker_exe=$maker_dir."/bin/maker";
    my $gff3_merge=$maker_dir."bin/gff3_merge";
    my $fasta_merge=$maker_dir."bin/fasta_merge";
    die("Cannot found executable file: maker in directory $maker_dir\n") unless(-e $maker_exe);
    die("Cannot found executable file: gff3_merge in directory $maker_dir\n") unless(-e $gff3_merge);
    die("Cannot found executable file: fasta_merge  in directory $maker_dir\n") unless(-e $fasta_merge);
    my $result_dir=$out_dir."result/";
    mkdir($result_dir);

#generate empty control files in the output directory   
    my $cmd_dir=$ENV{'PWD'};
    chdir "$out_dir";
    my $com="$maker_exe -CTL";
    system("$com");
    chdir "$cmd_dir";
    my $bopts_file=$out_dir."maker_bopts.ctl";
    my $opts_file=$out_dir."maker_opts.ctl";
    my $exe_file=$out_dir."maker_exe.ctl";

#read the configure file
    open(IN,$maker_ctg)||die("Error09: cannot read the file: $maker_ctg\n");
    my %config;
    while(my $line=<IN>){
        chomp $line;
        next if $line=~/^#/;
        my @string=split "=", $line;
        $config{$string[0]}=$line;
    }
    close IN;
    open(IN,$opts_file)||die("Error09: cannot read the file: $opts_file.\n");
    my $new_opts_file=$out_dir."new.maker_opts.ctl";
    open(OUT,">$new_opts_file")||die("Error10: cannot write the file: $new_opts_file.\n");
    while(my $line=<IN>){
        chomp $line;
        if(($line=~/^#/)||($line=~/^\s*$/)){
            print OUT $line."\n";
        }
        else{
            my @string=split "=",$line;
            if(exists($config{$string[0]})){
                print OUT $config{$string[0]}."\n";
            }
            else{
                print OUT $line."\n";
            }
        }
    }
    close IN;
    close OUT;
    open(IN,$bopts_file)||die("Error09: cannot read the file: $bopts_file.\n");
    my $new_bopts_file=$out_dir."new.maker_bopts.ctl";
    open(OUT,">$new_bopts_file")||die("Error10: cannot write the file: $new_bopts_file.\n");
    while(my $line=<IN>){
        chomp $line;
        if(($line=~/^#/)||($line=~/\s*$/)){
            print OUT $line."\n";
        }
        else{
            my @string=split "=",$line;
            if(exists($config{$string[0]})){
                print OUT $config{$string[0]}."\n";
            }
            else{
                print OUT $line."\n";
            }
        }
    }
    close IN;
    close OUT;
    open(IN,$exe_file)||die("Error09: cannot read the file: $exe_file.\n");
    my $new_exe_file=$out_dir."new.maker_exe.ctl";
    open(OUT,">$new_exe_file")||die("Error10: cannot write the file: $new_exe_file.\n");
    while(my $line=<IN>){
        chomp $line;
        if(($line=~/^#/)||($line=~/\s*$/)){
            print OUT $line."\n";
        }
        else{
            my @string=split "=",$line;
            if(exists($config{$string[0]})){
                print OUT $config{$string[0]}."\n";
            }
            else{
                print OUT $line."\n";
            }
        }
    }
    close IN;
    close OUT;

#read sample
    opendir(DATA,$data_dir) || die("Error: can not open the data directory: $data_dir!\n");
    my @samples=readdir(DATA);
    closedir DATA;
    foreach my $s (@samples){
        next if $s=~/^\./;
        my $sd=$data_dir.$s."/";
        my $out_sd=$out_dir.$s."/";
        mkdir($out_sd);
        print STDERR "Warning: $sd isn't a directory! => Not processed.\n" unless -d $sd;
        next unless -d $sd;
        print STDERR "Process sample $sd:\n";
        opendir(RUN,$sd)|| die("Error: can not open directory: $sd\n");
        my @files=readdir(RUN);
        close RUN;
        foreach my $file (@files){
            next if $file=~/^\./;
            if ($file=~/.fa/){
             $com="cp $new_bopts_file $out_sd/maker_bopts.ctl\n";
             $com.="cp $new_exe_file $out_sd/maker_exe.ctl\n";
             $com.="cp $new_opts_file $out_sd/maker_opts.ctl\n";
             my $target_file=$data_dir.$s."/".$file;
             my $input_file=$out_sd.$file;
             $com.="cp $target_file $input_file\n";
             system($com);
             $com="$maker_exe -c $thread_num -fix_nucleotides -genome $file\n";
             chdir "$out_sd";
             system($com);
             chdir "$cmd_dir";
             my $log_file=$out_sd.$s.".maker.output/".$s."_master_datastore_index.log";
             my $fasta_prefix=$result_dir.$s;
             my $gff_file=$result_dir.$s.".all.maker.gff";
             $com="$fasta_merge -d $log_file -o $fasta_prefix\n";
             $com.="$gff3_merge -d $log_file -o $gff_file\n";
             system($com);
            }
        }
    }
    unlink $new_bopts_file;
    unlink $new_opts_file;
    unlink $new_exe_file;
    unlink $bopts_file;
    unlink $opts_file;
    unlink $exe_file;
}
1;
