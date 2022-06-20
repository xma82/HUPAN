#!/usr/bin/perl
##Created by Duan Zhongqu, 2018-10-22
use strict;
use warnings;
package blastAlign;

sub blastAlign{
my $usage="\nUsage: hupan blastAlign [commands]

hupan blastAlign is used to make index of blast database and align sequence to database by blast.

Available commands:

      mkblastdb           Make the index of database by blast.
      blast               Align sequence to the database in parallel.

";

    die $usage if @ARGV<1;
    my $com=shift @ARGV;
    if($com eq "mkblastdb"){
        makeblastdb(@ARGV);
    }
    elsif($com eq "blast"){
        blast(@ARGV);
    }
    else{
        print STDERR "Unknown command: $com\n";
        die($usage);
    }
}
1;
sub makeblastdb{
    use Getopt::Std;
    use vars qw($opt_h $opt_a);
    getopts("ha:");
    
my $usage="\nUsage: hupan blastAlign mkblastdb [option] <database_file> <out_directory> <blast_directory>

hupan blastAlign mkblastdb is used to make index of blast database.

Necessary input description:

  <database_file>         <string>    The database file.

  <out_directory>         <string>    The index result will store in this directory.

  <blast_directory>       <string>    Directory where makeblastdb locate.

Options:
      -h                              Print this usage page.
      
      -a                  <string>    The datebase type, 'n' means nucleotide sequence,
                                      and 'p' means protein sequence. Default: n

"; 
    
    die $usage if @ARGV!=3;
    die $usage if defined($opt_h);
    my ($db_file,$out_dir,$tool_dir)=@ARGV;

#check blast
    $tool_dir.="/" unless $tool_dir=~/\/$/;
    my $exeMk=$tool_dir."makeblastdb";
    die(" $exeMk doesn't exist!\n") unless -e $exeMk;

#check existence of output directory
    if(-e $out_dir){
        die("Error: output directory \"$out_dir\" already exists.\nTo avoid overwriting of existing files, we kindly request that the\n output directory should not exist.\n");
    }
    $out_dir.="/" unless $out_dir=~/\/$/;
    mkdir $out_dir;
    my $out_data=$out_dir."/data";
    mkdir($out_data);

#check database file
    die(" $db_file doesn't exist!\n") unless -e $db_file;
    my $errf=$out_data."log.txt";

#chech the type of database
    my $db_type="nucl";
    if(defined($opt_a)){
       if(($opt_a eq "nucl")||($opt_a eq "prot")){
           $db_type=$opt_a;
       }
       else{
           print STDERR ("Unknown database type\n");
           die($usage);
       }
    }

#build index
    my $index=$out_data."blastdb";
    print STDERR "Build blast index for $db_file ...\n";
    my $com="$exeMk -dbtype $db_type -in $db_file -out $index 1>&2 2>$errf\n";
    system($com);
}
1;

sub blast{
    use Getopt::Std;
    use vars qw($opt_h $opt_t $opt_a $opt_n $opt_e $opt_s);
    getopts("ht:a:n:e:s:");

my $usage="\nUsage: hupan  blastAlign blast [options] <data_directory> <output_directory> <index_file> <blast_directory>

hupan blastAlign blast is used to align the sequences from multiple individual in parallel.

Necessary input description:

  data_directory          <string>    This directory should contain many sub-directories
                                      named by sample names, such as Sample1, Sample2, etc.
                                      In each sub-directory, there should be several
                                      files ended by \".fa\" or \".fa.gz\".

  output_directory        <string>    Output directory.

  index_file              <string>    The index file.

  blast_directory         <string>    directory where blastn or blastp locate.

Options:
     -h                               Print this usage page.

     -t                   <int>       Threads used.
                                      Default: 1

     -a                   <string>    The sequence type, 'n' means nucleotide sequence 
                                      and 'p' means protein sequence.
                                      Default: n

     -n                   <int>       The maximum number of target sequences.
                                      Default: 1

     -e                   <foalt>     The cutoff of e-value. 
                                      Default: 10-5

     -s                   <string>    Suffix of files within data_directory.
                                      Default: \".fa\"

";

    die $usage if @ARGV!=4;
    die $usage if defined($opt_h);
    my ($data_dir,$out_dir,$db_index,$tool_dir)=@ARGV;

#check existence of output directory
   if(-e $out_dir){
       die("Error: output directory \"$out_dir\" already exists.\nTo avoid overwriting of existing files, we kindly request that the\n output directory should not exist.\n");
   }

#get the sequence type
   my $db_type="n";
   if(defined($opt_a)){
       if(($opt_a eq "n")||($opt_a eq "p")){
           $db_type=$opt_a;
       }
       else{
           print STDERR ("Unknown database type\n");
           die($usage);
       }
    }

#check blast
    $tool_dir.="/" unless $tool_dir=~/\/$/;
    my $exeBlast;
    if($db_type eq "n"){
        $exeBlast=$tool_dir."blastn";
        die(" $exeBlast does't exist!\n") unless -e $exeBlast;
    }
    elsif($db_type eq "p"){
        $exeBlast=$tool_dir."blastp";
        die(" $exeBlast does't exist!\n") unless -e $exeBlast;
    }

#check thread number
    my $thread_num=1;
    $thread_num=$opt_t if defined $opt_t;

#check the maximum number of target sequence
    my $max_target_seq=1;
    $max_target_seq=$opt_n if defined $opt_n;

#check the cutoff of e-value
    my $e_value=10-5;
    $e_value=$opt_t if defined $opt_e;

#define file suffix
    my $suffix=".fa";
    $suffix=$opt_s if defined($opt_s);

#adjust directory names and create output directory
    $data_dir.="/" unless($data_dir=~/\/$/);
    $out_dir.="/" unless($out_dir=~/\/$/);

    mkdir $out_dir;
    my $out_data=$out_dir."data/";
    mkdir($out_data);

#read sample
    opendir(DATA,$data_dir) || die("Error: can not open input data directory!\n");
    my @sample=readdir(DATA);
    closedir DATA;

#process each sample
    foreach my $s (@sample){
        next if $s=~/^\./;
        my $s_dir=$data_dir.$s."/";
        print STDERR "Process sample $s ...\n";
        my $o_dir=$out_data.$s."/";
        mkdir($o_dir);
        opendir(DATA,$s_dir) || die("Error: can not read input data directory: $s_dir\n");
        my @files=readdir(DATA);
        closedir DATA;
        my %fq_base;
        foreach my $f (@files){
            next if $f=~/^\.+$/;
            print STDERR "Warnig: $f without suffix: $suffix\n" unless $f=~/$suffix$/;
            next unless $f=~/$suffix$/;
            $fq_base{$f}=1 unless defined($fq_base{$f});
        }
        foreach my $b (keys(%fq_base)){
            my $in_file=$s_dir.$b;
            my $fb=substr($b,0,length($b)-length($suffix)-1);
            my $blast_out=$o_dir.$fb.".blast";
            my $com="$exeBlast -query $in_file -db $db_index -out $blast_out -evalue $e_value -outfmt 7 -max_target_seqs $max_target_seq -num_threads $thread_num\n";
            system($com);
        }
    }
}
1;
