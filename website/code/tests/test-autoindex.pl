#!/usr/bin/perl
use strict;
use warnings;
use lib qw/./;

$|++;

use UniOrdner::AutoIndex qw/collect_data/;
use Data::Dumper;

my $dirname = $ARGV[0];
die "Usage: $0 <dirname>" unless $dirname;
print "Testing $dirname\n";
my %data = ('files'=>[]);
my $ret;
my $r = {};

$ret = UniOrdner::AutoIndex->collect_data(\%data, $dirname, $r);
print "Return value: ", Dumper($ret);
