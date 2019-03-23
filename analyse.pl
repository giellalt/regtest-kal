#!/usr/bin/env perl
# -*- mode: cperl; indent-tabs-mode: nil; tab-width: 3; cperl-indent-level: 3; -*-
use strict;
use warnings;
use utf8;

BEGIN {
	$| = 1;
	binmode(STDIN, ':encoding(UTF-8)');
	binmode(STDOUT, ':encoding(UTF-8)');
}
use open qw( :encoding(UTF-8) :std );
use feature 'unicode_strings';

use FindBin qw($Bin);
use lib "$Bin/";
use Helpers;

my $runner = "$Bin/../nutserut/regtest/runner.pl";
if (! -e $runner) {
   $runner = "$Bin/regtest/runner.pl";
}
system $runner, (@ARGV, '-b', "$Bin/kal.pl", '-f', $Bin);

if ($@) {
   die("Error: Regtest couldn't be run - run Nutserut's setup script!\n");
}

my @fs = glob("$Bin/output-*-fst.txt");
foreach my $f (@fs) {
   my ($bn) = ($f =~ m@output-(\S+?)-@);

   my $fst = file_get_contents($f);
   my @errs = ($fst =~ m/(\t"[^\n]+?"[^\n]+?"[^\n]*)/g);
   if (@errs) {
      my $err = join("\n", @errs);
      $err =~ s/("[^"\n]+")/\e[91m$1\e[39m/g;
      $err =~ s/\t\e\[91m"/\t"/g;
      print "ERROR in $bn: FST output has 3+ quotes, likely caused by missing root.lexc entries:\n";
      print $err."\n";
      print "\n";
   }

   @errs = ($fst =~ m/(\t"[^\n]+?" \?)/g);
   if (@errs) {
      my $err = join("\n", @errs);
      print "ERROR in $bn: FST could not provide analysis for:\n";
      print $err."\n";
      print "\n";
   }
}
