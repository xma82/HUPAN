#!/usr/bin/perl
#Created by Duan Zhongqu, 2018-10-21
package simSeq;

sub simSeq{
    my $usage="\nUsage: hupanLSF simSeq [commands] ...

hupanLSF simSeq is used to simulate and plot the total size of novel sequences.

Avaiblable commands:

       simNovelSeq       Simulate the total size of novel sequences by adding the individual one by one
       plotNovelSeq      Plot the size of the total size of novel sequences

";

    die $usage if @ARGV<1;
    my $com=shift @ARGV;
    if($com eq "simNovelSeq"){
        simNovelSeq(@ARGV);
    }
    elsif($com eq "plotNovelSeq"){
        plotNovelSeq(@ARGV);
    }
    else{
        print STDERR "Unknown command: $com\n";
        die($usage);
    }
}
1;
sub simNovelSeq{
    use strict;
    use warnings;
    use Getopt::Std;
    use vars qw($opt_h $opt_n $opt_t $opt_c);
    getopts("hn:t:c:");
    my $usage="\nUsage: hupanSLURM simSeq simNovelSeq [options] <data_path> <output_directory> <cdhit_directory>

hupanSLURM simSeq simNovelSeq is used to simulate the size of total novel sequences from individual novel sequences.

Necessary input description:

  data_path               <string>    This directory should contain many sub-directories
                                      named by sample names, such as sample1, sample2,etc.
                                      In each sub-directory, there should be novel sequences
                                      file ended by \".contig\".

  out_path                <string>    Results will be output to this directory. To avoid 
                                      overwriting of existing files, we kindly request
                                      that the output_directory should not exist. It is
                                      to say, this directory will be created by the 
                                      script itself.

  cdhit_directory         <string>    Directory where cd-hit-est locates.

Options:
     -h                               Print this usage.

     -n                   <int>       Specifies the number of random sampling times for
                                      simulation. 
                                      Default: 1
     
     -t                   <int>       Threads used.
                                      Default: 1

     -c                   <float>     Sequence identity threshold
                                      Default: 0.9
";

    die $usage if @ARGV!=3;
    die $usage if defined($opt_h);
    my ($data_dir,$out_dir,$tool_dir)=@ARGV;

#check existense of output directory
    if(-e $out_dir){
        die("Error: output directory \"$out_dir\" already exists. To avoid overwriting of existing files, we kindly request that the output directory should not exist.\n");
    }

#get simulation number 
    my $number=1;
    $number=$opt_n if defined $opt_n;
    
    my $thread_num=1;
    $thread_num=$opt_t if defined $opt_t;

    my $iden=0.9;
    $iden=$opt_c if defined $opt_c;

#adjust directory names and create output directory
    $data_dir.="/" unless($data_dir=~/\/$/);
    $out_dir.="/" unless($out_dir=~/\/$/);
    mkdir($out_dir);

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

#check cdhit-est
    $tool_dir.="/" unless($tool_dir=~/\/$/);
    my $exe=$tool_dir."cd-hit-est";
    die(" $exe doesn't exist!\n") unless -e $exe;

#read samples
    opendir(DATA,$data_dir) || die("Error: can not open input data directory!\n");
    my @tmp=readdir(DATA);
    closedir DATA;
    my @sample;
    foreach my $s (@tmp){
        next if $s=~/^\./;
        push @sample, $s;
    }

    my $result_file=$out_dir."result_out.txt";
    open(FILE1,">$result_file")||die("Error10: cannot write the file: $result_file\n");
    print FILE1 "Simulation time\tSample number\tSequence number\tSequence length\n";
    close FILE1;

#conduct simulations
    foreach (my $n=1;$n<=$number;$n++){
        my $simulation_dir=$out_dir."simulation".$n."/";
        mkdir $simulation_dir;
        my @samples=@sample;
        for(my $i=0;$i<@sample;$i++){
            my $j=int(rand(scalar(@samples)));
            my $sample=$samples[$j];
            splice @samples,$j,1;
            my $individual_file=$data_dir.$sample."/".$sample.".fa";
            my $num=$i+1;
            my $contig_file=$simulation_dir.$num."_raw.fa";
            my $com="cp $individual_file $contig_file";
            system($com);
        }
        my $in_file=$simulation_dir."novel.sequence.fa";
        my $individual_file=$simulation_dir."1_raw.fa";
        my $com="\ncp $individual_file $in_file";
        my $outfile=$simulation_dir."1_non.redundant.fa";
        $com.="\n$exe -i $in_file -o $outfile -T $thread_num -c $iden";
        $com.="\nfor((\$i=2;\$i<=".@sample.";\$i++));\ndo\nk=\$((\$i-1));";
        $individual_file=$simulation_dir."\$i_raw.fa";
        my $novel_file=$simulation_dir."\$k_non.redundant.fa";
        $com.="\ncat $individual_file $novel_file >$in_file";
        $outfile=$simulation_dir."\$i_non.redundant.fa";
        $com.="\n$exe -i $in_file -o $outfile -T $thread_num -c $iden";
        $com.="\ndone;";
        #print $com."\n";
#generate and submit job script
##************** Might be modified for different task submission system *******************
        my $job_file=$script_out."/sim$n.lsf";   #script_file
        my $err_file=$stderr_out."/sim$n.err";   #stderr_output_file
        my $out_file=$stdout_out."/sim$n.out";   #stdout_output_file
        #create job script
        open(JOB,">$job_file")||die("Error05: Unable to create job file: $job_file\n");
        print JOB "\#BSUB -J sim$n\n";              #job name
        #print JOB "\#BSUB -q fat\n";                     #queue name in the submission system
        print JOB "\#BSUB -o $out_file\n";               #stdout
        print JOB "\#BSUB -e $err_file\n";               #stderr
        print JOB "\#BSUB -n $thread_num\n";             #thread number
        print JOB "\#BSUB -R \"span[ptile=$thread_num]\"\n";
        print JOB "$com\n";                              #commands
        close JOB;
        system("bsub <$job_file");                       #submit job
#*****************************************************************************************
    }       
}
1;
sub plotNovelSeq{
    use strict;
    use warnings;
    use Getopt::Std;
    use vars qw($opt_h);
    getopts("h");
    my $usage="\nUsage: hupanLSF simSeq plotNovelSeq [commands] <data_directory> <out_directory>

hupanLSF simSeq plotNovelSeq is used to plot the total size of novel sequences from 'simNovelSeq' result.

Necessary input description:
   
  <data_directory>         <string>       Directory where 'simNovelSeq' result locates.

  <out_directory>          <string>       Output directory.

Options:
  -h                                      Print this usage page.
";

    die $usage if @ARGV!=2;
    die $usage if defined($opt_h);
    my ($data_dir,$out_dir)=@ARGV;

#check existence of output directory
    if(-e $out_dir){
       die("Error: output directory \"$out_dir\" already exists.\nTo avoid overwriting of existing files, we kindly request that the\n output directory should not exist.\n");
    }
    $out_dir.="/" unless $out_dir=~/\/$/;
    mkdir $out_dir;
    my $result_file=$out_dir."result_out.txt";
    open(OUT,">$result_file")||die("Error10: cannot write the file: $result_file.\n");
    print OUT "Simulation\tSample number\tSequence number\tSequence length\n";
    close OUT;

    $data_dir.="/" unless($data_dir=~/\/$/);
    opendir(DATA,$data_dir) || die("Error: can not open input data directory!\n");
    my @simulations=readdir(DATA);
    closedir DATA;

    foreach my $simulation (@simulations){
        next if $simulation=~/^\./;
        my $simulation_dir=$data_dir.$simulation."/";
        print STDERR "Warning: $simulation_dir isn't a directory! => Not processed.\n" unless -d $simulation_dir;
        next unless -d $simulation_dir;
        opendir(RUN,$simulation_dir)|| die("Error: can not open directory: $simulation_dir\n");
        my @files=readdir(RUN);
        close RUN;
        foreach my $f (@files){
            if($f=~/non.redundant.fa$/){
                my $out_file=$simulation_dir.$f;
                my $count=substr($f,0,length($f)-length("_non.redundant.fa"));
                open(IN,$out_file)||die("Error9: cannot read the file: $out_file.\n");
                my $seq_count=0;
                my $seq_length=0;
                while(my $line=<IN>){
                    chomp $line;
                    if($line=~/^>/){
                        $seq_count+=1;
                    }
                    else{
                        $seq_length+=length($line);
                    }
                }
                open(OUT,">>$result_file")||die("cannot write the file: $result_file.\n");
                print OUT $simulation."\t".$count."\t".$seq_count."\t".$seq_length."\n";
                close IN;
                close OUT;
            }
        }    
    }
    my $exec="plotNovelSeq.R";
    my @path=split /:/,$ENV{PATH};
    my $fpflag=0;
    foreach my $p (@path){
        $p.="/".$exec;
        if(-e $p && -x $p){
            $fpflag=1;
            $exec=$p;
            last;
        }
    }
    if($fpflag){
        my $com="Rscript $exec $result_file $data_dir";
        system($com);
    }
    else{
        print STDERR ("plotNovelSeq.R cannot be found in your PATH! Omit plotting!\n");
        return 0;
    }
}
1;
