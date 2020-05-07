#!/usr/bin/perl -w

#####  Convert 1Point3 acres file into the Yu group format;
## Usage:  
##   cat  1p3a_0503.csv | bin/convert1p3a2Common.pl > 
##                           2020-05-05/onePt3A_infections.csv

use warnings;
use strict;
use Carp;
use English;
use Getopt::Long;


GetOptions (
    );

my $header = <>;
chomp $header;
my @header = split /,/, $header;
my @casesHeader;
my @deathsHeader;

my %colIndices;

### stash the indices of the columns to save;
foreach my $index (0..$#header) {
    my $colName = $header[$index];
    if ($colName eq "STATEFP") {
	$colIndices{stateFIPS} = $index;
	next;
    }
    if ($colName eq "COUNTYFP") {
	$colIndices{countyFIPS} = $index;
	next;
    }

    ## reformat to #Cases_<data>
    if ($colName =~ s/^(\d{4})\-(\d{2})\-(\d{2})$/#Cases_$2-$3-$1/) {
	push @casesHeader, $colName;
	push @{$colIndices{cases} }, $index;
	next;
    }
    ## reformat to #Deaths_<data>
    if ($colName =~ s/^d(\d{4})\-(\d{2})\-(\d{2})$/#Deaths_$2-$3-$1/) {
	push @deathsHeader, $colName;
	push @{$colIndices{deaths} }, $index;
	next;
    }
    if ($colName eq "confirmed_count") {
	$colIndices{confirmed_count} = $index;
	next;
    }
    if ($colName eq "death_count") {
	$colIndices{death_count} = $index;
	next;
    }
    
}  ## foreach header index

my @outputHeader = ("countyFIPS", @casesHeader, @deathsHeader);
print join (",", @outputHeader), "\n";
while(<>) {
    chomp;
    my @F = split /,/;
    my $cumCases = 0;
    my $cumDeaths = 0;
    my $fips = $F[$colIndices{stateFIPS}] . $F[$colIndices{countyFIPS}];
    my @output = ($fips);
    map { $cumCases += $_;
	  push @output, $cumCases;
    } @F[@{$colIndices{cases}}];

    map { $cumDeaths += $_;
	  push @output, $cumDeaths;
    } @F[@{$colIndices{deaths}}];

    ## check the cumulative sum of the new daily counts agrees
    ##    with the reported value
    if ($cumCases != $F[$colIndices{confirmed_count}]) {
	carp "For fips $fips: cumCases $cumCases don't equal death count ",
	    $F[$colIndices{confirmed_count}];
    } 
    if ($cumDeaths != $F[$colIndices{death_count}]) {
	carp "For fips $fips: cumDeaths $cumDeaths don't equal death count ",
	    $F[$colIndices{death_count}];
    } 
    print join(",", @output), "\n";
}  ## while <>

__END__
