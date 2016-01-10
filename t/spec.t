#!perl

use 5.010;
use strict;
use warnings;

use File::ShareDir::Tarball qw(dist_dir);
use File::Slurper 'read_text';
use Ledger::Parser;
use Ledger::Journal;
#use Test::Differences;
use Test::Exception;
use Test::More 0.98;
use Test::LongString;

my $dir = dist_dir('Ledger-Examples');
diag ".dat files are at $dir";

#my $parser = Ledger::Parser->new;

my @files = glob "$dir/examples/*.dat";
#diag explain \@files;

for my $file (@files) {
    next if $file =~ /TODO-/;
    diag explain $file;
    subtest "file $file" => sub {
        if ($file =~ /invalid-/) {
            dies_ok { Ledger::Journal->new('parser' => Ledger::Parser->new('file' => $file))->validate; } "dies";
        } else {
            my $journal;
            lives_ok { $journal = Ledger::Journal->new('parser' => Ledger::Parser->new('file' => $file)); $journal->as_string; } "lives"
                or return;
        };
    };
    if (0 && $file !~ /invalid-/
	) {
	my $orig_content = read_text($file);
	my $journal = Ledger::Journal->new('parser' => Ledger::Parser->new('file' => $file));
	is_string($journal->as_string, $orig_content);
	$journal->cleanup;
	is_string_nows($journal->as_string, $orig_content);
    }
}

DONE_TESTING:
done_testing;
