package Comparisons;
use strict;
use warnings;
use Carp;
 
use Exporter qw(import);
our @EXPORT = qw(
    removeUncommonColumnsAndRows
    countDiffs
    printPair
);


sub removeUncommonColumnsAndRows {
    my @data = @ {shift()};
    my %allHeaders = % {shift()};
    my %allFIPS = %{ shift()};
    my @columns2Delete = ();
    foreach my $i (0..$#data) {
	my %data = %{$data[$i]};
	my @FIPS = keys %data;

	my @columns = keys %{$data{$FIPS[0]}};
	my %columns;
	map{$columns{$_} = 1} @columns;
	foreach my $col (keys %allHeaders) {
	    if (not exists $columns{$col}) {
		push @columns2Delete, $col;
	    }
	} ## foreach column
    } ## foreach $i
    foreach my $i (0..$#data) {
	my %data = %{$data[$i]};
	my @FIPS = keys %data;
	
	foreach my $fips (sort @FIPS) {
	    ## this is missing rows that have all zeros in one and a nonzero
	    ## in another;  maybe add this later; 
	    if ($allFIPS{$fips} != scalar @data) {
		carp "Removing fips $fips from data source $i\n";
		delete $data{$fips};
		next;
	    } ## if
	    delete @{$data{$fips}}{@columns2Delete};
	}  ## foreach fips
	$data[$i] = \%data;
    } ## foreach data source
    return \@data;
} ## sub remove columns and rows

sub countDiffs {
    my @data = @{ shift()};

    my @FIPS = sort {$a<=>$b} keys %{$data[0]};
    my @columns = sort keys %{$data[1]->{$FIPS[0]}};
    my %diffs;
    
    foreach my $fips (@FIPS) {
	my %counts;
	foreach my $col (@columns) {
	    my $diff = $data[0]->{$fips}->{$col} - $data[1]->{$fips}->{$col};
	    $counts{$diff} ++;
	}
	$diffs{$fips} = \%counts;
	#print "$fips";
	#map {print join "=>", ",$_",$counts{$_}} (sort {$a<=>$b} keys %counts);
	#print "\n";
    } ## foreach
    return \%diffs;

} ## sub countDiffs

sub printPair {
    my @data = @{shift()};
    my $fips = shift;
    my @files = @{shift()};
    map{s%^.*/(.....).*$%$1%} @files;

    my %d0 = %{$data[0]->{$fips}};
    my %d1 = %{$data[1]->{$fips}};
    my @colName = sort keys %d0;
    map{s/^#(.).*_(\d{2}-\d{2})-\d{4}$/${1}_$2/} @colName;
    print join("\t", $fips, @colName), "\n";
    print join("\t", $files[0], @d0{sort keys %d0}), "\n";
    print join("\t", $files[1], @d1{sort keys %d1}), "\n";
    print "\n";
}
1;
