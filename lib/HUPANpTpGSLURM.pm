#!/usr/bin/perl
package pTpG;

sub pTpG{
use strict;
use warnings;
use Getopt::Std;
use vars qw($opt_h $opt_e $opt_f);
getopts("hef");
my $usage="\nUsage: hupan pTpG [options] inputfile outputfile

hupan pTpG is used to obtain the longest transcript of each protein-coding genes from annotation file.
Notice: a file named \"protein_coding.gtf\" will be automatically prodcued to store all the protein-coding genes.

Necessary input description:

  inputfile            <string>      Annotation file. Default: \"gff\" format.
                                     If the annotation file is \"gtf\", please use the option \"-f\".
    
  outputfile           <string>      Outputfile.

Options: 

      -h                             Print this usage page.

      -e                             Check \"exon\" length instead of check \"CDS\" length.

      -f                             The annotation file is \"gtf\" format.
";

#print @ARGV;
die $usage if @ARGV!=2;
die $usage if defined($opt_h);
my ($gff_file,$out_file)=@ARGV;

my $format="gff";
$format="gtf" if defined($opt_f);

open(IN,$gff_file)||die("Error: cannot read the file: $gff_file.\n");
my $temp_file="protein_coding.gtf";
open(OUT,">$temp_file")||die("Error: cannot write the file: $temp_file.\n");
my $pre_gid="";
my $pre_tid="";
my %genes;

while(my $line=<IN>){
    chomp $line;
    next if $line=~/^#/;
    my ($chr,$source,$type,$start,$end,$score,$sym,$phase,$record)=split /\t/,$line;
    if($format eq "gff"){
        my @string=split /[;|=]/,$record;
        if($type eq "gene"){
            if($string[5] eq "protein_coding"){
                $pre_gid=$string[3];
            }
        }else{
            if($string[5] eq $pre_gid){
                $pre_tid=$string[7];
                print OUT "$chr\t$source\t$type\t$start\t$end\t$score\t$sym\t$phase\tgene_id \"$pre_gid\"; transcript_id \"$pre_tid\";\n";
            }
        }
    }else{
        if($type eq "gene"){
            $record=~/(gene_id \"[^\"]+\"); (gene_type \"[^\"]+\")/;
            if($2 eq "gene_type \"protein_coding\""){
                $pre_gid=$1;
            }
        }else{
            $record=~/(gene_id \"[^\"]+\"); (transcript_id \"[^\"]+\")/;
            if($1 eq $pre_gid ){
                $pre_tid=$2;
                print OUT "$chr\t$source\t$type\t$start\t$end\t$score\t$sym\t$phase\t$pre_gid; $pre_tid;\n";
            }
        }
    }
}
close IN;
close OUT;

my ($Vec, $num) = @{Read_GTF($temp_file)};

#open(OUT,">$out");
open(OUT,">$out_file")||die("Error: cannot write the file: $out_file.\n");
foreach my $d (@{$Vec}){
    my $target=$d->[0];
    my $len=getLen($d->[0]);
    for(my $i=1;$i<@{$d};$i++){
	my $nlen=getLen($d->[$i]);
	if($nlen>$len){
	    $len=$nlen;
	    $target=$d->[$i];
	}
    }
    if($len!=0){
		OutputTran($target);
    }
}

exit;


########## sub routines ###########
sub getLen{
    my ($d)=@_;
    my $len=0;
    foreach my $k (@{$d}){
	if(defined $opt_e){
	    if($k->{type} eq "exon"){
		$len+=$k->{end}-$k->{start}+1;
	    }
	}
	else{
	    if($k->{type} eq "CDS" ||$k->{type} eq "stop_codon"){
		$len+=$k->{end}-$k->{start}+1;
	    }
	}
    }
    return $len;
}

sub OutputTran{              #\@tvec,$name ,output file
    my ($ad) = @_;
    my $d1;
    for($d1=0;$d1<@{$ad};$d1++){
	print OUT "${${$ad}[$d1]}{chr}\t";
	print OUT "${${$ad}[$d1]}{source}\t";
	print OUT "${${$ad}[$d1]}{type}\t";
	print OUT "${${$ad}[$d1]}{start}\t";
	print OUT "${${$ad}[$d1]}{end}\t";
	print OUT "${${$ad}[$d1]}{score}\t";
	print OUT "${${$ad}[$d1]}{sym}\t";
	print OUT "${${$ad}[$d1]}{phase}\t";
	print OUT "${${$ad}[$d1]}{gid}; ";
	print OUT "${${$ad}[$d1]}{tid};\n";
    }
}

sub Read_GTF{
    my ($file) = @_;
    my @gvec;
    my @re;
    my $begin = 1;
    my $pre_tid;
    my $pre_gid;
    my $i = 0;
    my $j = 0;
    my $k = 0;
    my @temp;
    open(IN,$file)||die "open $file error:$!\n";
    while(<IN>){
	chomp;
	if(/^[0-9a-zA-Z]+/){
	    if($begin == 1){
		@temp = split("\t",$_);
		$temp[8]=~/(gene_id \"[^\"]+\"); (transcript_id \"[^\"]+\")/;
		$pre_tid = $2;
		$pre_gid = $1;

		$gvec[$i] = init_gene();
		${$gvec[$i]}[$j] = init_tran();

		${${$gvec[$i]}[$j]}[$k] =
			  new_sf($temp[0],$temp[1],$temp[2],$temp[3],$temp[4],$temp[5],$temp[6],$temp[7],$1,$2);
		$begin = 0;
	    }
	    else{
		@temp = split("\t",$_);
		$temp[8] =~ /(gene_id \"[^\"]+\"); (transcript_id \"[^\"]+\")/;

		if($1 eq $pre_gid){
		    if($2 eq $pre_tid){
			$k++;
			${${$gvec[$i]}[$j]}[$k] =
				  new_sf($temp[0],$temp[1],$temp[2],$temp[3],$temp[4],$temp[5],$temp[6],$temp[7],$1,$2);
		    }
		    else{
			$j++;
			${$gvec[$i]}[$j] = init_tran();
			$k = 0;
			${${$gvec[$i]}[$j]}[$k] = 
				  new_sf($temp[0],$temp[1],$temp[2],$temp[3],$temp[4],$temp[5],$temp[6],$temp[7],$1,$2);
			$pre_tid = $2;
		    }
		}
		else{
		    $i++;
		    $gvec[$i] = init_gene();
		    $j = 0;
		    ${$gvec[$i]}[$j] = init_tran();
		    $k = 0;
		    ${${$gvec[$i]}[$j]}[$k] = 
			      new_sf($temp[0],$temp[1],$temp[2],$temp[3],$temp[4],$temp[5],$temp[6],$temp[7],$1,$2);
		    $pre_gid =$1;
		    $pre_tid = $2;
		}
	    }
	}
    }
    close IN;
    $re[0] = \@gvec;
    $re[1] = scalar(@gvec);
    return \@re;
}

sub new_sf{             
    my ($chr,$src,$type,$start,$end,$score,$sym,$phase,$gid,$tid)=@_;
    my %hash = (
	"chr" => $chr,
	"source" => $src,
	"type" => $type,
	"score" => $score,
	"gid" => $gid,
	"tid" => $tid,
	"start" => $start,
	"end" => $end,
	"sym" => $sym,
	"phase" => $phase,
    );
    return \%hash;
}

sub init_gene{
    my @a;
    return \@a;
}
sub init_tran{
    my @a;
    return \@a;
}
1;
}
1;
