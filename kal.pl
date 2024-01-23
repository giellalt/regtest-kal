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
my $args = ' '.join(' ', @ARGV).' ';

my $cmdline = "$Bin/../kal/tools/shellscripts/kal-tokenise $Bin/../kal/tools/tokenisers/tokeniser-disamb-gt-desc.pmhfst | cg-sort | REGTEST_AUTO fst | vislcg3 -g $Bin/../kal/src/cg3/kal-pre1.cg3 --trace | REGTEST_CG pre1 | $Bin/../kal/tools/shellscripts/kal-hybrid-split $Bin/../kal/src/fst/generator-gt-desc.hfstol | cg-sort | REGTEST_AUTO hybrids | vislcg3 -g $Bin/../kal/src/cg3/kal-pre2.cg3 --trace | REGTEST_CG pre2 | vislcg3 -g $Bin/../kal/src/cg3/disambiguator.cg3 --trace | REGTEST_CG morf | vislcg3 -g $Bin/../kal/src/cg3/functions.cg3 --trace | REGTEST_CG syntax | vislcg3 -g $Bin/../kal/src/cg3/dependency.cg3 --trace | REGTEST_CG dep | perl -wpne 's~ [^/\\s]+/[^/\\s]+~~g; s~ i[A-Z\\d]\\w*~~g; s~\\x{E020}~\\x{20}~g; while(s~( DIRTALE[A-Z]+)\\1~\$1~g){}' | cg-sort | REGTEST_AUTO no2nd";

if ($args =~ / --regtest / && $args =~ / --raw /) {
   print "BIN/kal-tokenise LEX/tokeniser-disamb-gt-desc.pmhfst | cg-sort | REGTEST_AUTO fst | vislcg3 -g ETC/kal-pre1.cg3 --trace | REGTEST_CG pre1 | BIN/kal-hybrid-split LEX/generator-gt-desc.hfstol | cg-sort | REGTEST_AUTO hybrids | vislcg3 -g ETC/kal-pre2.cg3 --trace | REGTEST_CG pre2 | vislcg3 -g ETC/disambiguator.cg3 --trace | REGTEST_CG morf | vislcg3 -g ETC/functions.cg3 --trace | REGTEST_CG syntax | vislcg3 -g ETC/dependency.cg3 --trace | REGTEST_CG dep | perl -wpne 's~ [^/\\s]+/[^/\\s]+~~g; s~ i[A-Z\\d]\\w*~~g; s~\\x{E020}~\\x{20}~g; while(s~( DIRTALE[A-Z]+)\\1~\$1~g){}' | cg-sort | REGTEST_AUTO no2nd\n";
}
elsif ($args =~ / --regtest /) {
   print $cmdline."\n";
}
else {
   $cmdline =~ s/ \| REGTEST[^|]+/ /g;
   open my $pipe, "$cmdline |";
   while (<$pipe>) {
      print;
   }
   close $pipe;
}
