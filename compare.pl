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
use File::Spec;

use FindBin qw($Bin);
use lib "$Bin/";
use Helpers;

use Getopt::Long;
Getopt::Long::Configure('no_ignore_case');
my $opt_help = 0;
my $opt_020 = 0;
my $opt_040 = 0;
my $opt_060 = 0;
my $rop = GetOptions(
	'help|?' => \$opt_help,
	'help|h' => \$opt_help,
	'fst|f' => \$opt_020,
	'pos|p' => \$opt_040,
	'syntax|s' => \$opt_060,
                    );

if ($opt_help) {
   my @cns = ();
   my @fs = glob("$Bin/input-*.txt");
   foreach my $f (@fs) {
      my ($bn) = ($f =~ m@$Bin/input-(\w+).txt@);
      push(@cns, $bn);
   }

   print "compare.pl [-f] [-p] [-s] [<corpus name>]\n";
   print "\n";
   print "Possible corpus names:\n\t".join("\n\t", @cns)."\n";
   print "\n";
   print "Cmdline flags:\n";
   print "  --fst, -f      Compare FST analyses\n";
   print "  --pos, -p      Compare POS tagging\n";
   print "  --syntax, -s   Compare syntactic functions\n";
   print "\n";
   print "Default is that all corpora and all comparison levels are enabled and will run in order FST, POS, syntax.\n";
   exit(0);
}

if (!$opt_020 && !$opt_040 && !$opt_060) {
   $opt_020 = $opt_040 = $opt_060 = 1;
}

my $tmpdir = File::Spec->tmpdir();

sub compare_010 {
   my ($bn,$o_10) = @_;

   print "\nComparing inputs\n";

   my @add = ();
   my @del = ();
   my $e_20 = load_output("$Bin/expected-$bn-020.txt");
   foreach my $h (keys(%$e_20)) {
      if (! defined $o_10->{$h}) {
         push(@del, $h);
      }
   }
   foreach my $h (keys(%$o_10)) {
      if (! defined $e_20->{$h}) {
         push(@add, $h);
      }
   }
   if (@add || @del) {
      if (@add) {
         @add = sort {$o_10->{$a}->[0] <=> $o_10->{$b}->[0]} @add;
         print "\nADDED INPUTS:\nLine\tText\n";
         foreach my $h (@add) {
            print $o_10->{$h}->[0]."\t".$o_10->{$h}->[1]."\n";
         }
      }
      if (@del) {
         @del = sort(@del);
         print "\nDELETED INPUTS:\nText\n";
         foreach my $h (@del) {
            print $e_20->{$h}->[1]."\n";
         }
      }
      print "\nWere the above input additions/deletions expected? [Y]es / [N]o: ";
      my $act = <STDIN>;
      if ($act !~ /^y/i) {
         print "\nQuitting to let you fix the input.\n";
         exit(1);
      }
      print "\nAccepted changes in input\n";
      #save_expected("$Bin/expected-$bn-010.txt", $o_10);
   }

   return 0;
}

sub compare_020 {
   my ($bn,$o_10) = @_;

   print "\nComparing FST analyses\n";

   my $did = 0;
   my @diff = ();
   my $e_20 = load_output("$Bin/expected-$bn-020.txt");
   my $o_20 = load_output("$Bin/output-$bn-020.txt");
   foreach my $h (keys(%$o_20)) {
      if (! defined $e_20->{$h}) {
         $did = 1;
         print "Accepting input line $o_10->{$h}->[0]: $o_10->{$h}->[1]\n";
         $e_20->{$h} = $o_20->{$h};
      }
      elsif ($o_20->{$h}->[1] ne $e_20->{$h}->[1]) {
         push(@diff, $h);
      }
   }
   foreach my $h (keys(%$e_20)) {
      if (! defined $o_20->{$h}) {
         $did = 1;
         delete($e_20->{$h});
      }
   }
   if (!@diff) {
      if ($did) {
         save_expected("$Bin/expected-$bn-020.txt", $e_20);
      }
      return 0;
   }

   print "FST analyses differ between '$Bin/expected-$bn-020.txt' and '$Bin/output-$bn-020.txt':\n";
   @diff = sort {$o_20->{$a}->[0] <=> $o_20->{$b}->[0]} @diff;
   my $all = 0;
   foreach my $h (@diff) {
      if ($all) {
         print "Accepting input line $o_10->{$h}->[0]: $o_10->{$h}->[1]\n";
         $e_20->{$h}->[1] = $o_20->{$h}->[1];
         next;
      }

      file_put_contents("$tmpdir/kal-expect.txt", $e_20->{$h}->[1]."\n");
      file_put_contents("$tmpdir/kal-output.txt", $o_20->{$h}->[1]."\n");
      print "\n";
      print "\e[31mLine $o_10->{$h}->[0]: \e[91m$o_10->{$h}->[1]\e[31m :\e[39m\n";
      print "\e[34m".`diff -bB -U 5 '$tmpdir/kal-expect.txt' '$tmpdir/kal-output.txt' | sed '1,3d'`."\e[39m";
      print "[A]ll ok / [O]k / [N]ot ok / [B]reak: ";
      my $act = <STDIN>;
      if ($act =~ /^[oa]/i) {
         $did = 1;
         $e_20->{$h}->[1] = $o_20->{$h}->[1];
      }
      if ($act =~ /^a/i) {
         $all = 1;
      }
      if ($act =~ /^b/i) {
         last;
      }
   }

   if ($did) {
      save_expected("$Bin/expected-$bn-020.txt", $e_20);
   }

   return 1;
}

sub compare_040 {
   my ($bn,$o_10) = @_;

   print "\nComparing POS tagging\n";

   my $did = 0;
   my @diff = ();
   #my $e_30 = load_output("$Bin/expected-$bn-030.txt");
   my $o_30 = load_output("$Bin/output-$bn-030.txt");
   my $e_40 = load_output("$Bin/expected-$bn-040.txt");
   my $o_40 = load_output("$Bin/output-$bn-040.txt");
   foreach my $h (keys(%$o_40)) {
      $o_40->{$h}->[1] = strip_secondary($o_40->{$h}->[1]);

      if (! defined $e_40->{$h}) {
         $did = 1;
         print "Accepting input line $o_10->{$h}->[0]: $o_10->{$h}->[1]\n";
         #$e_30->{$h} = $o_30->{$h};
         $e_40->{$h} = $o_40->{$h};
      }
      elsif ($o_40->{$h}->[1] ne $e_40->{$h}->[1]) {
         push(@diff, $h);
      }
   }
   foreach my $h (keys(%$e_40)) {
      if (! defined $o_40->{$h}) {
         $did = 1;
         #delete($e_30->{$h});
         delete($e_40->{$h});
      }
   }
   if (!@diff) {
      if ($did) {
         #save_expected("$Bin/expected-$bn-030.txt", $e_30);
         save_expected("$Bin/expected-$bn-040.txt", $e_40);
      }
      return 0;
   }

   print "Tagging differs between '$Bin/expected-$bn-040.txt' and '$Bin/output-$bn-040.txt':\n";
   @diff = sort {$o_40->{$a}->[0] <=> $o_40->{$b}->[0]} @diff;
   my $all = 0;
   foreach my $h (@diff) {
      if ($all) {
         print "Accepting input line $o_10->{$h}->[0]: $o_10->{$h}->[1]\n";
         #$e_30->{$h}->[1] = $o_30->{$h}->[1];
         $e_40->{$h}->[1] = $o_40->{$h}->[1];
         next;
      }

      file_put_contents("$tmpdir/kal-expect.txt", collapse_cohorts($e_40->{$h}->[1])."\n");
      file_put_contents("$tmpdir/kal-output.txt", collapse_cohorts($o_40->{$h}->[1])."\n");
      print "\n";
      print "\e[31mLine $o_10->{$h}->[0]: \e[91m$o_10->{$h}->[1]\e[31m :\e[39m\n";
      print "\e[34m".expand_cohorts(scalar `diff -bB -U 4 '$tmpdir/kal-expect.txt' '$tmpdir/kal-output.txt' | sed '1,3d'`)."\e[39m";
      print "\n";
      PROMPT:
      print "[A]ll ok / [O]k / [N]ot ok / [T]race / [B]reak: ";
      my $act = <STDIN>;
      if ($act =~ /^[oa]/i) {
         $did = 1;
         #$e_30->{$h}->[1] = $o_30->{$h}->[1];
         $e_40->{$h}->[1] = $o_40->{$h}->[1];
      }
      if ($act =~ /^a/i) {
         $all = 1;
      }
      if ($act =~ /^b/i) {
         last;
      }
      if ($act =~ /^t/i) {
         print "\e[94m".$o_30->{$h}->[1]."\e[39m\n";
         goto PROMPT;
      }
   }

   if ($did) {
      #save_expected("$Bin/expected-$bn-030.txt", $e_30);
      save_expected("$Bin/expected-$bn-040.txt", $e_40);
   }

   return 1;
}

sub compare_060 {
   my ($bn,$o_10) = @_;

   print "\nComparing syntactic functions\n";

   my $did = 0;
   my @diff = ();
   #my $e_50 = load_output("$Bin/expected-$bn-050.txt");
   my $o_50 = load_output("$Bin/output-$bn-050.txt");
   my $e_60 = load_output("$Bin/expected-$bn-060.txt");
   my $o_60 = load_output("$Bin/output-$bn-060.txt");
   foreach my $h (keys(%$o_60)) {
      $o_60->{$h}->[1] = strip_secondary($o_60->{$h}->[1]);

      if (! defined $e_60->{$h}) {
         $did = 1;
         print "Accepting input line $o_10->{$h}->[0]: $o_10->{$h}->[1]\n";
         #$e_50->{$h} = $o_50->{$h};
         $e_60->{$h} = $o_60->{$h};
      }
      elsif ($o_60->{$h}->[1] ne $e_60->{$h}->[1]) {
         push(@diff, $h);
      }
   }
   foreach my $h (keys(%$e_60)) {
      if (! defined $o_60->{$h}) {
         $did = 1;
         #delete($e_50->{$h});
         delete($e_60->{$h});
      }
   }
   if (!@diff) {
      if ($did) {
         #save_expected("$Bin/expected-$bn-050.txt", $e_50);
         save_expected("$Bin/expected-$bn-060.txt", $e_60);
      }
      return 0;
   }

   print "Tagging differs between '$Bin/expected-$bn-060.txt' and '$Bin/output-$bn-060.txt':\n";
   @diff = sort {$o_60->{$a}->[0] <=> $o_60->{$b}->[0]} @diff;
   my $all = 0;
   foreach my $h (@diff) {
      if ($all) {
         print "Accepting input line $o_10->{$h}->[0]: $o_10->{$h}->[1]\n";
         #$e_50->{$h}->[1] = $o_50->{$h}->[1];
         $e_60->{$h}->[1] = $o_60->{$h}->[1];
         next;
      }

      file_put_contents("$tmpdir/kal-expect.txt", collapse_cohorts($e_60->{$h}->[1])."\n");
      file_put_contents("$tmpdir/kal-output.txt", collapse_cohorts($o_60->{$h}->[1])."\n");
      print "\n";
      print "\e[31mLine $o_10->{$h}->[0]: \e[91m$o_10->{$h}->[1]\e[31m :\e[39m\n";
      print "\e[34m".expand_cohorts(scalar `diff -bB -U 4 '$tmpdir/kal-expect.txt' '$tmpdir/kal-output.txt' | sed '1,3d'`)."\e[39m";
      print "\n";
      PROMPT:
      print "[A]ll ok / [O]k / [N]ot ok / [T]race / [B]reak: ";
      my $act = <STDIN>;
      if ($act =~ /^[oa]/i) {
         $did = 1;
         #$e_50->{$h}->[1] = $o_50->{$h}->[1];
         $e_60->{$h}->[1] = $o_60->{$h}->[1];
      }
      if ($act =~ /^a/i) {
         $all = 1;
      }
      if ($act =~ /^b/i) {
         last;
      }
      if ($act =~ /^t/i) {
         print "\e[94m".$o_50->{$h}->[1]."\e[39m\n";
         goto PROMPT;
      }
   }

   if ($did) {
      #save_expected("$Bin/expected-$bn-050.txt", $e_50);
      save_expected("$Bin/expected-$bn-060.txt", $e_60);
   }

   return 1;
}

my @fs = glob("$Bin/input-*.txt");
foreach my $f (@fs) {
   my ($bn) = ($f =~ m@$Bin/input-(\w+).txt@);

   if ($ARGV[0] && $bn !~ /$ARGV[0]/) {
      next;
   }

   print "Handling $bn ...\n";
   my $o_10 = load_output("$Bin/output-$bn-010.txt");
   compare_010($bn, $o_10);

   if ($opt_020) {
      compare_020($bn, $o_10);
   }

   if ($opt_040) {
      compare_040($bn, $o_10);
   }

   if ($opt_060) {
      compare_060($bn, $o_10);
   }
}
