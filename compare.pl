#!/usr/bin/env perl
# -*- mode: cperl; indent-tabs-mode: nil; tab-width: 3; cperl-indent-level: 3; -*-
use strict;
use warnings;
use FindBin qw($Bin);

if (@ARGV && $ARGV[0] !~ /^-/) {
   @ARGV = ('-c', $ARGV[0]);
}

chdir($Bin);

my $regtest = "../regtest/regtest.pl";
system $regtest, (@ARGV, '-b', "./kal.pl", '-f', './');

if ($@) {
   die("Error: Regtest couldn't be run - run Nutserut's setup script!\n");
}
