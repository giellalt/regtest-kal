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
use Digest::SHA qw(sha1_base64);

use FindBin qw($Bin);
use lib "$Bin/";
use Helpers;

use Getopt::Long;
Getopt::Long::Configure('no_ignore_case');
my $opt_help = 0;
my $opt_verbose = 0;
my $rop = GetOptions(
	'help|?' => \$opt_help,
	'help|h' => \$opt_help,
	'verbose|v' => \$opt_verbose,
                    );

if ($opt_help) {
   my @cns = ();
   my @fs = glob("$Bin/input-*.txt");
   foreach my $f (@fs) {
      my ($bn) = ($f =~ m@$Bin/input-(\w+).txt@);
      push(@cns, $bn);
   }

   print "analyse.pl [-v] [<corpus name>]\n";
   print "\n";
   print "Possible corpus names:\n\t".join("\n\t", @cns)."\n";
   print "\n";
   print "Cmdline flags:\n";
   print "  --verbose, -v  Show verbose output from kal-tokenise\n";
   print "\n";
   print "Default is that all corpora are enabled.\n";
   exit(0);
}

my $v = '';
if ($opt_verbose) {
   $v = '-v';
}

if (! -s './tools/tokenisers/tokeniser-disamb-gt-desc.pmhfst') {
   print "Can't find ./tools/tokenisers/tokeniser-disamb-gt-desc.pmhfst - make sure you are in the kal folder.\n";
   exit(1);
}

my @fs = glob("$Bin/input-*.txt");
foreach my $f (@fs) {
   my ($bn) = ($f =~ m@$Bin/input-(\w+).txt@);

   if ($ARGV[0] && $bn !~ /$ARGV[0]/) {
      next;
   }

   print "Handling $bn ...\n";
   print "\tinput $f\n";
   `rm -rfv $Bin/output-$bn-*`;

   print "\tdelimiting by lines\n";
   my $i = 0;
   my %uniq = ();
   my @sents = ();
   my @ins = split(/\n+/, file_get_contents($f));
   foreach (@ins) {
      ++$i;
      $_ =~ s/#[^\n]*//g;
      $_ = trim($_);
      $_ =~ s/\s\s+/ /g;
      if (!$_ || /^</) {
         # Skip empty or commented lines
         next;
      }
      my $s = $_;
      utf8::encode($s); # sha1_base64() can't handle UTF-8 for some reason
      my $hash = sha1_base64($s);
      $hash =~ s/[^a-zA-Z0-9]/x/g;
      if (defined $uniq{$hash}) {
         # Skip duplicate inputs
         next;
      }
      $uniq{$hash} = 1;
      push(@sents, "<s$hash-$i>\n".$_."\n</s$hash-$i>\n<STREAMCMD:FLUSH>");
   }

   @sents = sort(@sents);
   file_put_contents("$Bin/output-$bn-010.txt", join("\n\n", @sents));

   my $cmd = "cat $Bin/output-$bn-010.txt";
   $cmd .= " | ./tools/shellscripts/kal-tokenise $v ./tools/tokenisers/tokeniser-disamb-gt-desc.pmhfst";
   $cmd .= " | cg-sort | tee $Bin/output-$bn-020.txt";
   $cmd .= " | vislcg3 -t -g ./src/syntax/disambiguator.cg3 --no-mappings";
   $cmd .= " 2>$Bin/output-$bn-030.err | cg-sort | tee $Bin/output-$bn-030.txt";
   $cmd .= " | cg-untrace";
   $cmd .= " | cg-sort | tee $Bin/output-$bn-040.txt";
   $cmd .= " | vislcg3 -t -g ./src/syntax/disambiguator.cg3";
   $cmd .= " 2>$Bin/output-$bn-050.err | cg-sort | tee $Bin/output-$bn-050.txt";
   $cmd .= " | cg-untrace";
   $cmd .= " | cg-sort | tee $Bin/output-$bn-060.txt";
   $cmd .= " >/dev/null";

   print "\ttokenising and analysing\n";
   `$cmd`;

   print "\n";

   my $fst = file_get_contents("$Bin/output-$bn-020.txt");
   my @errs = ($fst =~ m/(\t"[^\n]+?"[^\n]+?"[^\n]*)/g);
   if (@errs) {
      my $err = join("\n", @errs);
      $err =~ s/("[^"\n]+")/\e[91m$1\e[39m/g;
      $err =~ s/\t\e\[91m"/\t"/g;
      print "ERROR: FST output has 3+ quotes, likely caused by missing root.lexc entries:\n";
      print $err."\n";
      print "\n";
   }

   @errs = ($fst =~ m/(\t"[^\n]+?" \?)/g);
   if (@errs) {
      my $err = join("\n", @errs);
      $err =~ s/("[^"\n]+")/\e[91m$1\e[39m/g;
      $err =~ s/\t\e\[91m"/\t"/g;
      print "ERROR: FST could not provide analysis for:\n";
      print $err."\n";
      print "\n";
   }
}
