#!/usr/bin/env perl
# -*- mode: cperl; indent-tabs-mode: nil; tab-width: 3; cperl-indent-level: 3; -*-
use strict;
use warnings;
use FindBin qw($Bin);

if (@ARGV && $ARGV[0] !~ /^-/) {
   @ARGV = ('-c', $ARGV[0]);
}

my $regtest = "$Bin/../regtest/regtest.pl";
system $regtest, (@ARGV, '-b', "$Bin/kal.pl", '-f', $Bin);

if ($@) {
   die("Error: Regtest couldn't be run - run Nutserut's setup script!\n");
}
