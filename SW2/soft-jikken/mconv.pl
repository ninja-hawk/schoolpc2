#!/usr/bin/perl

# $Id: mconv.pl,v 1.1.1.1 2001/04/08 06:29:47 nom Exp $
#
# mconv.pl -- make .org line from mapfile.
#
# Yoshinari Nomura <nom@csce.kyushu-u.ac.jp>
#
# usage: mconv.pl mapfile obj_filename srcfile > newsrc
#

($mapfile, $objname, $srcfile) = @ARGV;

open(MAP, $mapfile);

print ".nolist\n";
while (<MAP>){
    if (/ *\.(text|data|bss)\s+(\S+)\s+(\S+)\s+$objname$/){
	($section, $start, $length) = ($1, $2, $3);
	print ".section .$section\n";
	print ".org $start\n";
    }
}
print ".section .text\n";
print ".list\n";
close(MAP);

open(SRC, $srcfile);
while (<SRC>){
    print $_;
}

exit 0;
