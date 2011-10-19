#!perl

use 5.010;
use strict;
use warnings;
use File::Slurp;
use FindBin qw($Bin);
use Ledger::Parser;
use Test::More 0.96;

my $ledgerp = Ledger::Parser->new;

sub test_parse {
    my %args = @_;
    my $j;
    eval {
        $j = $ledgerp->parse($args{ledger});
    };
    my $eval_err = $@;
    if ($args{dies}) {
        ok($eval_err, "dies");
    } else {
        ok(!$eval_err, "doesn't die") or do {
            diag $eval_err;
            return;
        };
    }
    if (defined $args{num_tx}) {
        is(scalar(@{$j->transactions}), $args{num_tx}, "num_tx");
    }
    if ($args{posttest}) {
        $args{posttest}->($j);
    }
}

my $ledger1 = read_file("$Bin/ledger1.dat");
test_parse
    ledger=>$ledger1,
    num_tx => 4,
    posttest => sub {
        my ($j) = @_;
        my $txs = $j->transactions;
        is(ref($txs), 'ARRAY', 'transactions() returns array');
        my $tx0 = $txs->[0];
        is_deeply($tx0->balance, [], 'balance()');
        ok($tx0->is_balanced, 'is_balanced()');

        # XXX test tx1 comment, tx2 comment
        # XXX test post comment
    };

done_testing();
