#!/usr/bin/perl
use strict;
use warnings;

$|++;

use UniOrdner::PermissionFile qw(find_permission_files printable_access);
use Data::Dumper;

my $file = $ARGV[0];
print "Testing $file\n";
my $res = UniOrdner::PermissionFile->quick_check_permission($file);
print "Access on $file: ",UniOrdner::PermissionFile->printable_access($res),"\n";
