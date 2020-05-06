#!/usr/bin/perl -w


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

    if ($colName =~ s/^(\d{4})\-(\d{2})\-(\d{2})$/#Cases_$2-$3-$1/) {
	push @casesHeader, $colName;
	push @{$colIndices{cases} }, $index;
	next;
    }
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
    
}

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
    if ($cumCases != $F[$colIndices{confirmed_count}]) {
	carp "For fips $fips: cumCases $cumCases don't equal death count ",
	    $F[$colIndices{confirmed_count}];
    } 
    if ($cumDeaths != $F[$colIndices{death_count}]) {
	carp "For fips $fips: cumDeaths $cumDeaths don't equal death count ",
	    $F[$colIndices{death_count}];
    } 

    print join(",", @output), "\n";
}
__END__
