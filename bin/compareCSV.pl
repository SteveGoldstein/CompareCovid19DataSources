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
my $nytFile = 'csv/nytimes_infections.csv';
my $usfFile = 'csv/usafacts_infections.csv';

my @urls = ($nytURL, $usfURL);
my @files = ($nytFile, $usfFile);

GetOptions (

            );

foreach my $i (0..1) {
    #my $curlOut = `curl -o $files[$i] $urls[$i] 2> /dev/null`;
    #print $curlOut unless ($curlOut =~ /^\s*$/);
}

my @data;
my %allHeaders;
my %allFIPS;
my %noCases;
## Bronx,Kings,etc counties are in usafacts but not nytimes
my %nycFIPS = (36005=>1,36047=>1,36061=>1,36081=>1,36085=>1);
$nycFIPS{'00001'} = 1;  ## skip New York City Unallocated/Probable
my $cruiseShipFIPS = '06000';

### parse each file and 
foreach my $i (0..$#files) {
    my $file = $files[$i];
    open F, $file or croak "Can't read $file";
    my $header = <F>;
    chomp $header;
    my @header = split /,/, $header;
    map{$allHeaders{$_} ++} @header[1..$#header];
    my %data;
    while (<F>) {
	chomp;
	my @F = split /,/;
	my $fips = $F[0];
	## New York City and Kansas City, MO are in the NYT file as City[12]
	next if ($fips =~ /^City[12]$/);
	next if (exists $nycFIPS{$fips});
	next if ($fips eq $cruiseShipFIPS);

	### skip the lines with no cases;
	my $skip = 1;
	foreach my $value (@F[1..$#F]) {
	    if ($value > 0) {
		$skip = 0;
		last;
	    } ##
	}  ## foreach value
	if ($skip) {
	    $noCases{$fips} ++;
	    next;
	}

	$allFIPS{$fips} ++;
	map{
	    ## data{fips} -> {#cases_date} = #cases;
	    $F[$_] =~ s/\.0+$//;
	    $data{$fips} -> {$header[$_]} = $F[$_];
	} (1..$#F);
    } ## while
    close F;
    push @data, \%data;
}
## compare FIPS;  expect all to be same;
foreach my $fips (sort {$a<=>$b} keys %allFIPS) {
    
    next if ($allFIPS{$fips} == scalar @files);
    my $no = $noCases{$fips} // 0;
    next if ($allFIPS{$fips} + $no == scalar @files);
    print "$fips only occurs in $allFIPS{$fips} file(s).\n";
}



print join("\t", "File", "#Columns", "MissingColumns"),"\n";
foreach my $i (0..$#data) {
    my $oneFIPS = (keys %allFIPS)[0];
    my @headers = keys %{$data[$i]->{$oneFIPS}};
    my %theseheaders;
    map {$theseheaders{$_} = 1} (@headers);
    my $same = 0;
    my @different = ();
    foreach my $column (sort keys %allHeaders) {
	if (exists $theseheaders{$column}) {
	    $same ++;
	}
	else {
	    push @different, $column;
	}
    } ## foreach column
    print join("\t", $files[$i], $same,join(",",@different)),"\n";
}
print "#" x 20, "\n";

@data = @{ removeUncommonColumnsAndRows(\@data,\%allHeaders,\%allFIPS)};
my @colNames = makeColNames($data[0]);

my %counts = %{countDiffs(\@data)};
my ($diffs,$l1Dist)  = calcDiffs(\@data);

foreach my $fips (sort keys %counts) {
    print "$fips";
    my %cnts = %{$counts{$fips}};
    map {print join "=>", ",$_",$cnts{$_}} (sort {$a<=>$b} keys %cnts);
    print "\n";
}

foreach my $fips (sort keys %counts) {
    my %cnts = %{$counts{$fips}};
    next unless (scalar keys %cnts > 20);
    printPair(\@data,$fips, \@files);
}


print join(",", "fips", @colNames),"\n";
foreach my $fips (sort {$l1Dist->{$b} <=> $l1Dist->{$a} } keys %$diffs) {
    print join(",",$fips,@{$diffs->{$fips}}), "\n";
}
########################

__END__
to do: remove columns that are not in common;
sort columns in same order;
then add stuff up.

20047 only occurs in 1 files   20047,Edwards County,KS  cases:  1 4/20
32015 only occurs in 1 files
51720 only occurs in 1 files     Norton city, VA
File	#Columns	MissingColumns
nytimes_infections.csv	182	
usafacts_infections.csv	180	#Cases_01-21-2020,#Deaths_01-21-2020
####################

## get the lines with most cases the last 2 days, 
cat nytimes_infections.csv |perl -F, -nale 'map{s/\.0$//;} @F; print join ",", @F[0, -2,-1,$#F/2-1,$#F/2]' >  n
cat usafacts_infections.csv |perl -F, -nale 'print join ",", @F[0, $#F/2-1,$#F/2,-2,-1]' > u


sort -t, -k3,3nr -k5,5nr -k1,1n u > uu
sort -t, -k3,3nr -k5,5nr -k1,1n n > nn

### now compare all non zero lines
head -2745 uu > uuu
head -2750 nn > nnn
cat uuu nnn|sort|uniq -d |wc -l  
or
cat uuu nnn|sort|uniq -u |less

760  cat usafacts_infections.csv |perl -F, -nale 'if ($.==1){map{$h{$_} = $F[$_]} (1..$#F);next}; next unless ($F[0] == 55025); map {s/\.0//} @F; map{print join "\t", $h{$_}, $F[$_]} (1..$#F); last'|sort > usDane
  761  cat nytimes_infections.csv |perl -F, -nale 'if ($.==1){map{$h{$_} = $F[$_]} (1..$#F);next}; next unless ($F[0] == 55025); map {s/\.0//} @F; map{print join "\t", $h{$_}, $F[$_]} (1..$#F); last'|sort > nyDane
  765  man join
  766  join nytimes_infections.csv usafacts_infections.csv |less -S
  767  head nytimes_infections.csv usafacts_infections.csv 
  768  join usDane nyDane |less
  769  man join
  770  join -a usDane nyDane |less
  771  join -a 1 usDane nyDane |less
  772  join -a 1 -a 2 usDane nyDane |less
  773  history > h
