#!/usr/bin/perl

# $Id: lconv.pl,v 1.1.1.1 2001/04/08 06:29:47 nom Exp $
#
# lconv.pl -- reformat gas's listing file to fit the bsvc.
#
# Yoshinari Nomura <nom@csce.kyushu-u.ac.jp>
#
# usge: lconv.pl file.gnulis > file.bsvclis
#

$OFFSET    = 0x000;
$skip_line = 5;  # xxx: adhoc

while ($ARGV[0] =~ /^-/){
    if ($ARGV[0] =~ /^--skip-line=(\d+)$/){
	$skip_line = $1;
	shift;
    } else {
	die "Usage: $0 [--skip-lint=n] listing > fixed-listing.\n";
    }
}

while (<>){
    chomp;
    next if (/^68K GAS.*\s+page 1$/);
    next if (/^\xc/);  # ignore ^L
    next if (/^$/);    # ignore blank line
    last if (/^DEFINED SYMBOLS/);

    if (/^\s*(\d+)\s([^\t]+)(\t(.*))?/){
	($line, $code, $source) = ($1, $2, $4);

	if ($code =~ /^([\da-zA-Z]+)(.*)/){
	    $address = hex($1) + $OFFSET;
	    $code =~ s/^[\da-zA-Z]+//;
	} else {
	    undef $address;
	}
	$code =~ s/^\s+//;
	$code =~ s/\s+$//;
	$line -= $skip_line;

	if (defined $address){
	    printf("%06x %-15s %3s %s\n", $address, $code, $line, $source);
	} else {
	    printf("%-6s %-15s %3s %s\n", ' ', $code, $line, $source);
	}
    } else {
	die "format error\n";
    }
}
