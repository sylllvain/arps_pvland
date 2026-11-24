#! /usr/bin/perl -w

use strict;

#
#  Reformat lat/long/elev data to be in a format that ARPSVERIF wants.
#

#
#  Your basic surface station list.
#
#  This file is in the GEMPAK distribution in "gempak/tables/stns/sfcstns.tbl".
#

my $file = "sfstns.tbl";
my $sfile;

open(F,"<$file") or die $file;
read(F,$sfile, 500000);
close(F);

my $file2 = "sfcstns.tbl";
open(G,">$file2") or die $file2;

print G "stn   lat    lon     elev(m)\n";

my @splits = split/\n/, $sfile;

foreach my $line ( @splits ) {

#
#  We'll do the brute force by extracting by specific columns.  Although we
#  could split by spaces, station locations can have spaces in them.
#
	my $stn = substr($line,0,4);
	my $lat = substr($line,55,5);
	my $lon = substr($line,61,6);
	my $elev = substr($line,69,4);
	my $lat2 = $lat / 100;
	my $lon2 = $lon / 100;
	my $line2 = sprintf "%4s %6.2f  %7.2f %4d\n",
		$stn, $lat2, $lon2, $elev;
	print G $line2;
}

#
#  Oklahoma Mesonet stations..
#

$file = "geomeso.csv";

open(F,"<$file") or die $file;
read(F,$sfile, 500000);
close(F);

@splits = split/\r/, $sfile;

foreach my $line ( @splits ) {
	my @split2 = split/,/, $line;
#
#  See if we have a station ID where we expect one.  If there isn't one, then
#  this is a line to be ignored.
#
	next if ( ! $split2[1] );
	my $stn = $split2[1];
	my $lat = $split2[7];
	my $lon = $split2[8];
	my $elev = $split2[9];
	my $line2 = sprintf "%4s %6.2f  %7.2f %4d\n",
		$stn, $lat, $lon, $elev;
	print G $line2;
}

#
#  West Texas Mesonet stations.  Note we handle leading "K" and "X", so both
#  the file transfer and LDM cases are handled.
#

$file = "wtxsta.table";

open(F,"<$file") or die $file;
read(F,$sfile, 500000);
close(F);

@splits = split/\n/, $sfile;

foreach my $line ( @splits ) {
	next if ( $line =~ /Station/ );

	my $stn = substr($line,0,4);
	my $lat = substr($line,22,7);
	my $lon = substr($line,32,9);
	my $elev = substr($line,45,6);
	my $line2 = sprintf "%4s %6.2f  %7.2f %4d\n",
		$stn, $lat, $lon, $elev;
	print G $line2;
	$line2 =~ s/K/X/;
	print G $line2;
}

close(G);

exit 0;
