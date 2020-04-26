#!/usr/bin/perl -w


use warnings;
use strict;
use Carp;
use English;
use Getopt::Long;
use lib "lib";
use Comparisons;

my $nytURL = 'https://raw.githubusercontent.com/Yu-Group/covid19-severity-prediction/master/data/county_level/processed/nytimes_infections/nytimes_infections.csv';
my $usfURL = 'https://raw.githubusercontent.com/Yu-Group/covid19-severity-prediction/master/data/county_level/processed/usafacts_infections/usafacts_infections.csv';
my $nytFile = 'nytimes_infections.csv';
my $usfFile = 'usafacts_infections.csv';

my @urls = ($nytURL, $usfURL);
my @files = ($nytFile, $usfFile);
my $outdir = './';
my $fetch = 1;

GetOptions (
    'outdir=s'   => \$outdir,
    'fetch!'     => \$fetch,
    );

map{$_ = "$outdir/$_"} @files;

if ($fetch) {
    foreach my $i (0..1) {
	my $curlOut = `curl -o $files[$i] $urls[$i] 2> /dev/null`;
	print $curlOut unless ($curlOut =~ /^\s*$/);
    }
}

my @data;
my %allColumns;
my %allFIPS;
my %noCases;
## Bronx,Kings,etc counties are in usafacts but not nytimes
my %skipFIPS = (36005=>1,36047=>1,36061=>1,36081=>1,36085=>1);
$skipFIPS{'00001'} = 1;  ## skip New York City Unallocated/Probable
my $cruiseShipFIPS = '06000';
$skipFIPS{$cruiseShipFIPS} = 1;

### parse each file and 
foreach my $i (0..$#files) {
    my $file = $files[$i];
    my $dataFromFile = parseFile(
	$file, \%allColumns,\%allFIPS,\%noCases, \%skipFIPS
	);
    push @data, $dataFromFile;
}

## find fips codes that do not occur in all files;
my $logFile = "$outdir/comparison.log";
open LOG, ">$logFile" or croak "Can't write to logfile $logFile";

my %addNulls;  
foreach my $fips (sort {$a<=>$b} keys %allFIPS) {
    
    next if ($allFIPS{$fips} == scalar @files);
    my $no = $noCases{$fips} // 0;
    if ($allFIPS{$fips} + $no == scalar @files) {
	### if this fips is in all the files, add back entries with zeros;
	$addNulls{$fips} = 1;
	next;
    }
    else {
	## otherwise just note that is isn't in all the files;
	print LOG "$fips only occurs in $allFIPS{$fips} file(s).\n";
    }
}

print LOG join("\t", "File", "#Columns", "MissingColumns"),"\n";
foreach my $i (0..$#data) {
    my $oneFIPS = (keys %allFIPS)[0];
    my @headers = keys %{$data[$i]->{$oneFIPS}};
    my %theseheaders;
    map {$theseheaders{$_} = 1} (@headers);
    my $same = 0;
    my @different = ();
    foreach my $column (sort keys %allColumns) {
	if (exists $theseheaders{$column}) {
	    $same ++;
	}
	else {
	    push @different, $column;
	}
    } ## foreach column
    print LOG join("\t", $files[$i], $same,join(",",@different)),"\n";
}
print LOG "#" x 20, "\n";

my @removed = removeUncommonColumnsAndRows(
    \@data,\%allColumns,\%allFIPS,\%addNulls);
@data = @{$removed[0]};
my @rmMsg = @{$removed[1]};
print LOG @rmMsg;
 
my @colNames = makeColNames($data[0]);

## calculate pairwise differences and order by l1 distance
my ($diffs,$l1Dist)  = calcDiffs(\@data);
print join(",", "fips", @colNames),"\n";
foreach my $fips (
    sort {
	## sort by l1 distance between rows
	$l1Dist->{$b} <=> $l1Dist->{$a} ||
	    $a <=> $b
    } 
    keys %$diffs) {
    print join(",",$fips,@{$diffs->{$fips}}), "\n";
}
########################

__END__

##### histogram of differences between rows
my %counts = %{countDiffs(\@data)};
foreach my $fips (sort keys %counts) {
    print "$fips";
    my %cnts = %{$counts{$fips}};
    map {print join "=>", ",$_",$cnts{$_}} (sort {$a<=>$b} keys %cnts);
    print "\n";
}
# print the ones with the most bins in the histogram
foreach my $fips (sort keys %counts) {
    my %cnts = %{$counts{$fips}};
    next unless (scalar keys %cnts > 20);
    printPair(\@data,$fips, \@files);
}
