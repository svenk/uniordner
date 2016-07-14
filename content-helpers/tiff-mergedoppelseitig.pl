#!/usr/bin/perl
#
# Doppelseitig einscannen mit nur einem Scanner? Ergebnis: Vorderseiten in einem
# (oder mehreren) TIFFs, Rueckseiten ebenso? Loesung:
#
#   mkdir vorderseiten; mkdir rueckseiten
#   tiffsplit vorderseiten.tif vorderseiten/
#   tiffsplit rueckseiten.tif rueckseiten/
#   ./merger vorderseiten/ rueckseiten/ output.pdf
#   acroread output.pdf
#
#   :-)
#   Sven Koeppel, 30.12.2010
#
#



use strict;
use Data::Dumper;

# program usage:
# ./merger vorderseitenverzeichnis rueckseitenverzeichnis output.pdf

unless(@ARGV == 3) {
	print "Usage:\”";
	print "\t$0 vorderseitenverzeichnis rueckseitenverzeichnis output.pdf\n";
	exit();
}

my ($evendir, $odddir, $outputfile) = @ARGV;

my @evenfiles; my @oddfiles; my @out;
@evenfiles = glob("$evendir/*.tif");
@oddfiles = glob("$odddir/*.tif");

# even odd merging
while(@evenfiles || @oddfiles) {
	push(@out, shift(@evenfiles)) if(@evenfiles);
	push(@out, shift(@oddfiles)) if(@oddfiles);
}

print "Joining these files: \n";
print Dumper(@out);

print "\n\n";
my $exec = "tiffcp ".join(", ", @out)." $outputfile.tif";

print $exec."\n";
`$exec`;

die "Merging failed.\n" if($?);

exit;

print "Creating PDF:\n";
my $exec = "tiff2pdf -pA4 -o $outputfile $outputfile.tif";
print $exec."\n";
`$exec`;

die "Creating PDF failed\n" if($?);
unlink("$outputfile.tif"); # was temporary
