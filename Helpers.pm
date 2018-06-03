#!/usr/bin/env perl
# -*- mode: cperl; indent-tabs-mode: nil; tab-width: 3; cperl-indent-level: 3; -*-
package Helpers;
use strict;
use warnings;
use utf8;
use Exporter qw(import);
our @EXPORT = qw(trim file_get_contents file_put_contents load_output save_output save_expected strip_secondary);

sub trim {
   my ($s) = @_;
   $s =~ s/^\s+//g;
   $s =~ s/\s+$//g;
   return $s;
}

sub file_get_contents {
   my ($fname) = @_;
   local $/ = undef;
   open FILE, '<:encoding(UTF-8)', $fname or die "Could not open ${fname}: $!\n";
   my $data = <FILE>;
   close FILE;
   return $data;
}

sub file_put_contents {
   my ($fname,$data) = @_;
   open FILE, '>:encoding(UTF-8)', $fname or die "Could not open ${fname}: $!\n";
   print FILE $data;
   close FILE;
}

sub load_output {
   my ($fname) = @_;
   my %data = ();
   if (! -s $fname) {
      return \%data;
   }

   my $body = file_get_contents($fname);
   my @chunks = split(m@\n</s[-\w]*>@, $body);
   foreach my $c (@chunks) {
      $c =~ s/<STREAMCMD:FLUSH>//g;
      if ($c !~ /<s(\w+)-(\d+)>\n(.+)$/s) {
         next;
      }
      my ($hash, $line, $chunk) = ($1, $2, $3);
      $chunk = trim($chunk);
      if (!$chunk) {
         print "ERROR: Entry $hash in $fname was empty!\n";
         exit(1);
      }
      my @lc = ($line, $chunk);
      $data{$hash} = \@lc;
   }

   return \%data;
}

sub save_output {
   my ($fname,$data) = @_;
   my @hs = sort(keys(%$data));
   open FILE, '>:encoding(UTF-8)', $fname or die "Could not open ${fname}: $!\n";
   foreach my $h (@hs) {
      my $id = "$h-".$data->{$h}->[0];
      print FILE "<s$id>\n".$data->{$h}->[1]."\n</s>\n\n";
   }
   close FILE;
}

sub save_expected {
   my ($fname,$data) = @_;
   my @hs = sort(keys(%$data));
   open FILE, '>:encoding(UTF-8)', $fname or die "Could not open ${fname}: $!\n";
   foreach my $h (@hs) {
      my $id = $h.'-0';
      print FILE "<s$id>\n".$data->{$h}->[1]."\n</s>\n\n";
   }
   close FILE;
}

sub strip_secondary {
   my ($str) = @_;
   while ($str =~ s/ i[^"\s\n]+(\s|\n|$)/$1/g) {}
   while ($str =~ s@ [^"/\s\n]+/[^"/\s\n]+(\s|\n|$)@$1@g) {}
   return $str;
}

1;
