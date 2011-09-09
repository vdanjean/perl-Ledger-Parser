#!perl

use 5.010;
use strict;
use warnings;
use File::Slurp;
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
        ok(!$eval_err, "doesn't die") or diag $eval_err;
    }
    if (defined $args{num_tx}) {
        is(scalar(@{$j->transactions}), $args{num_tx}, "num_tx");
    }
    if ($args{post_test}) {
        $args{post_test}->($j);
    }
}

my $ledger1 = <<'_';


; comment
; another comment

2011-09-09    transaction 1
 acc1:subacc1  $11,203.01
 acc2:subacc two  USD 10,000
 ; comment
 acc2:subacc3



09/09 (2) transaction 2
 acc1:subacc1             20 USD
 acc2:subacc2            USD -20
09-09 (3) transaction 3
 (acc1)                   $ 20
 acc2:subacc two:subsub    -30
 acc2:subacc3               30

09-09 (3) transaction 4
 [acc1]                 20
 acc2:subacc2          -45
 acc2:subacc3           25

P 2011/09/09 USD 8500 IDR
_

test_parse ledger=>$ledger1, num_tx => 4;
done_testing();
