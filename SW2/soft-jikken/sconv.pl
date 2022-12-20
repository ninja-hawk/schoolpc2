#!/usr/bin/perl

#################################################################
# sconv.pl
#
# Convert normal S record file to it's subset
# which contains only S[0258] records.
# if S3 and S7 records couldn't be convered, 
# sconv will emit an error and exit.
#
# $Id: sconv.pl,v 1.1.1.1 2001/04/08 06:29:47 nom Exp $
#
# Yoshinari Nomura (nom@csce.kyushu-u.ac.jp)
#
################################################################

################################################################
#
#  Motorola S-Record File Format.
#  http://home.socal.rr.com/awi/srecords.htm
#
#  The S-Record file format is designed to contain data intended for
#  programming into various types of PROM (Programmable Read Only
#  Memory). Each S-Record is a self contained memory segment and as
#  such data fragments may come out of sequence.
#
#  An S-Record looks like:
#
#            S<type><length><address><data><checksum><cr/lf>
#  where:
#
#      type      The type of S-Record. S0, S1, S2, S3, S5, S7, S8, S9
#
#      length    The remaining count byte-pairs. Includes the address,
#                data and checksum fields.
#
#      address   The destination address for the record. The length of
#                this field is determined by the address type.
#
#      data      Byte pairs representing an image of the data to be
#                placed at address.
#
#      checksum  The checksum is the sum of all the raw byte data in the
#                record, from the length upwards, modulo 256 and subtracted
#                from 255.
#
#  Note: The length member is not the number of chars following, since
#        it takes two chars to represent a byte.
#
#  S-Record Types:
#
#  S0: Header record. Normally contains a comment describing the
#      contents of the file. The data and address are ignored.
#      Intended as documentation field only.
#
#  S1: Data record. The address field is 16-Bit wide.
#
#  S2: Data record. The address field is 24-Bit wide.
#
#  S3: Data record. The address field is 32-Bits wide.
#
#  S5: Record count record. Sum of records contained in the file.
#
#  S7: Termination record. The address field is a 32-Bit wide field
#      which can be optionally used for the entry address to the
#      memory image.
#
#  S8: Termination record. The address field is a 24-Bit wide field
#      which can be optionally used for the entry address to the
#      memory image.
#
#  S9: Termination record. The address field is a 16-Bit wide field
#      which can be optionally used for the entry address to the
#      memory image.
#
#  Example S-Record.
#
#   S0   06     FFFF    486472     DD
#   S3   09   00000000 12345678    E2
#   S7   05   00000000             FA
################################################################

$DEBUG  = 0;
$record = 0;

$nl     = "\n";

while (<>){
    chomp;
    s/\x0d$//;
    print "- $_$nl+ " if $DEBUG;
    
    if (/^S0/) {
	print "S00600004844521B$nl";

    } elsif (/^S1..(....)(.*)..$/){
	# 16 to 24
	print_s(2, "00" . $1 . $2);
	$record++;

    } elsif (/^S2/){
	# 24 to 24
	print $_, "$nl";
	$record++;

    } elsif (/^S3..00(......)(.*)..$/){
	# 32 to 24
	print_s(2, $1 . $2);
	$record++;

    } elsif (/^S5/){
	# skip, print S5 later when S[789] will be out.
	next;

    } elsif (/^S7..00(......)..$/){
	# 32 to 24
	print_s(5, sprintf("%04X", $record));
	print_s(8, $1);
	
    } elsif (/^S8..(......)..$/){
	# 24 to 24
	print_s(5, sprintf("%04X", $record));
	print $_, "$nl";

    } elsif (/^S9..(....)..$/){
	# 16 to 24
	print_s(5, sprintf("%04X", $record));
	print_s(8, "00" . $1);
    } else {
	print STDERR "sconv: Unknown record ($_).\n";
	exit(1);
    }
}

exit(0);

sub print_s
{
    my $type = shift;
    my @data = split_hexstr(shift);

    my $len  = ($#data + 1) + 1;  # length of data and checksum.
    my $sum  = $len;

    printf("S%d%02X", $type, $len);

    foreach (@data){
	$sum = ($sum + $_) % 256;
	printf("%02X", $_);
    }
    $sum = 255 - $sum;
#    if ($type == 8) { $nl = ''; } else { $nl = "\r"; }
    printf("%02X$nl", $sum);
}

sub split_hexstr
{
    my $hexstr = shift;
    my @ret;

    while ($hexstr =~ s/^(..)//){
	push(@ret, hex($1));
    }
    return @ret;
}
