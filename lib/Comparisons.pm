package Comparisons;
use strict;
use warnings;
use Carp;
 
use Exporter qw(import);
our @EXPORT = qw(
    parseFile
    removeUncommonColumnsAndRows
    countDiffs
    calcDiffs
    printPair
    printPairHeader
    makeColNames
);

#### Parse the processed file from UC Berkeley and return a hash ref
## with data structure:
##        $data->{fips} -> {#cases_date} = #cases;
##        $data->{fips} -> {#deaths_date} = #deaths;

sub parseFile {
    my $file = shift;
    my $columns = shift; 
    my $allFIPS = shift; 
    my $noCases = shift;
    my $skipFIPS = shift; 

    open F, $file or croak "Can't open processed file $file";
    my $header = <F>;
    chomp $header;
    my @header = split /,/, $header;
    map{$columns->{$_} ++} @header[1..$#header];
    my %data;
    while (<F>) {
	chomp;
	my @F = split /,/;
	my $fips = $F[0];
	## New York City and Kansas City, MO are in the NYT file as City[12]
	next if ($fips =~ /^City[12]$/);
	next if (exists $skipFIPS->{$fips});

	### skip the lines with no cases;
	my $skip = 1;
	foreach my $value (@F[1..$#F]) {
	    if ($value > 0) {
		$skip = 0;
		last;
	    } ##
	}  ## foreach value
	if ($skip) {
	    $noCases->{$fips} ++;
	    next;
	}

	$allFIPS->{$fips} ++;
	map{
	    ## data{fips} -> {#cases_date} = #cases;
	    ## data{fips} -> {#deaths_date} = #deaths;
	    $F[$_] =~ s/\.0+$//;
	    $data{$fips} -> {$header[$_]} = $F[$_];
	} (1..$#F);
    } ## while
    close F;
    return \%data;
}
sub removeUncommonColumnsAndRows {
    my @data = @ {shift()};
    my %allHeaders = % {shift()};
    my %allFIPS = %{ shift()};
    my %addNulls = % {shift()};
    
    my @columns2Delete = ();
    my @rmMsg;
    
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
	my @allColumns = keys %{$data{$FIPS[0]}};
	
	## add a row of zeros for the fips in addNulls;
	map {
	    if (not exists $data{$_}) {
		push @FIPS, $_;
		$allFIPS{$_} ++;
		foreach my $col (@allColumns) {
		    $data{$_}->{$col} = 0;
		}
	    }
	} keys %addNulls;
	
	my @fips2Remove;
	foreach my $fips (sort @FIPS) {
	    if ($allFIPS{$fips} != scalar @data) {
		push @fips2Remove, $fips;
		next;
	    } ## if
	    delete @{$data{$fips}}{@columns2Delete};
	}  ## foreach fips
	delete @data{@fips2Remove};
	if (scalar @fips2Remove) {
	    my $rmMsg = "Removed fips " . 
		join(",", @fips2Remove) . " from file ";
	    push @rmMsg, $rmMsg;
	}
	else {
	    push @rmMsg, "All fips retained from file ";
	}
	$data[$i] = \%data;
    } ## foreach data source
    return (\@data,\@rmMsg);
} ## sub remove columns and rows

sub countDiffs {
    my @data = @{ shift()};

    my @FIPS = sort {$a<=>$b} keys %{$data[0]};
    my @columns = sort keys %{$data[0]->{$FIPS[0]}};
    my %diffs;
    
    foreach my $fips (@FIPS) {
	my %counts;
	foreach my $col (@columns) {
	    my $diff = $data[0]->{$fips}->{$col} - $data[1]->{$fips}->{$col};
	    $counts{$diff} ++;
	}
	$diffs{$fips} = \%counts;
    } ## foreach
    return \%diffs;

} ## sub countDiffs

sub calcDiffs {
    my @data = @{ shift()};

    my @FIPS = sort {$a<=>$b} keys %{$data[0]};
    my @columns = sort keys %{$data[0]->{$FIPS[0]}};
    
    my %diffs;
    my %l1Dist;
    foreach my $fips (@FIPS) {
	my %counts;
	my @diffs;
	foreach my $col (@columns) {
	    my $diff = $data[0]->{$fips}->{$col} - $data[1]->{$fips}->{$col};
	    push @diffs, $diff;
	}
	$diffs{$fips} = \@diffs;
	my $l1 = 0;
	map{$l1 += abs} @diffs;
	$l1Dist{$fips} = $l1;
    } ## foreach
    return (\%diffs,\%l1Dist);
} ## sub calcDiffs

## to do: change this to printHeader and printLine(0,1 or (0,1)
sub printPairHeader {
    my @data = @{shift()};
    return printPair(\@data);
}

sub printPair {
    my @data = @{shift()};
    my $fips = shift;
    my @files = @{shift() || [] };
    my $printHeader = shift || 0;
    my $printLines = 1;
    
    my $output = '';

    if (not defined $fips) {
	## get a dummy fips to enable formatting the column names, etc;
	$fips = (keys %{$data[0]})[0];
	$printHeader = 1;
	$printLines = 0;
    }
    ## to do: make this an array of hash refs;
    my %d0 = %{$data[0]->{$fips}};
    my %d1 = %{$data[1]->{$fips}};
    my @colName = makeColNames($data[0]);
    if ($printHeader) {
	$output .= join(",", "fips", @colName) . "\n";
    }
    if ($printLines) {
	my @source = @files;
	map {s%^.*/([^/]+)_infections\.csv$%$1%;} @source;

	$output .= join(",", $fips, $source[0], @d0{sort keys %d0}) . "\n";
	$output .= join(",", $fips, $source[1], @d1{sort keys %d1}) . "\n";
    }
    return $output;
}

sub makeColNames {
    my %data = %{ shift()};
    my $oneFIPS = (keys %data)[0];
    my @colName = sort keys %{$data{$oneFIPS}};
    map{s/^#(.).*_(\d{2}-\d{2})-\d{4}$/${1}_$2/} @colName;
    return(@colName);
} # sub makeColNames;

1;
