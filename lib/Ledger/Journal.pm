package Ledger::Journal;

use 5.010;
use locale;
use Array::Iterator;
use Log::Any '$log';
use Moo;
use Ledger::Transaction;
use Ledger::Posting;
#use Ledger::Pricing;
use Time::HiRes qw(gettimeofday tv_interval);

# VERSION

has raw_lines => (is => 'rw');
has entries => (is => 'rw'); # either L::Transaction or L::Separator

my $re_date     = $Ledger::Transaction::re_date;
my $re0_tx      = qr/^\d/;
my $re_tx       = qr/^(?<date>$re_date)
                     (\s+\(?<seq>\d+\)\s*)?
                     (?:\s+(?<desc>.+))?/x;
my $re_accpart  = qr/(?:
                         [^:\s]+|
                         \s|
                         (?:[^:\s]+\s)+|
                         (?:\s[^:\s]+)+
                     )/x; # don't allow double space
my $re_acc0     = qr/(?:$re_accpart(?::$re_accpart)*)/;
my $re_acc      = qr/(?:$re_acc0|\($re_acc0\)|\[$re_acc0\])/;
my $re_comment  = qr/^\s*;/;
my $re0_posting = qr/^\s+[^;\s]/;
my $re_posting  = qr/^\s+(?<acc>$re_acc)\s{2,}($re_amount)\s*(?:;.*)?$/x;
my $re0_pricing = qr/^P\s+/x;
my $re_pricing  = qr/^P\s+/x; # we don't parse it atm. (date)? cmd1 amount cmd2

sub BUILD {
    my ($self, $args) = @_;

    if (!$self->raw_lines) {
        $self->raw_lines([]);
    }
    if (!$self->entries) {
        $self->entries([]);
    }
    $self->_parse;
}

sub as_string {
    my ($self) = @_;
    join "", @{$self->raw_lines};
}

sub _add_tx {
}

sub _parse {
    my ($self) = @_;
    $log->tracef('-> _parse()');
    my $t0 = [gettimeofday];

    my $i = Array::Iterator->new($self->raw_lines);
  PARSE:
    while ($i->hasNext) {
        my $line = $i->next;
        if ($line =~ $re0_tx) {
            die "Invalid transaction syntax on line $i" unless $line !~ $re_tx;
            eval {
                $tx = Ledger::Transaction->new(
                    date => $+{date}, seq => $+{seq}, description=>$+{desc},
                    _line => $linum,
                );
            };
            die "Can't parse transaction on line ".$i->currentIndex.": $@"
                if $@;
            # get postings
            while (1) {
                $line = $i->peek;
                last if !defined($line);
                last unless $line =~ /^\s/;
                $i->next;
            }

                $linum++;
        }
            if ($line =~ $re0_posting) {
                die "Invalid posting syntax on line $i"
                    unless $line !~ $re_posting;
                my $p;
                eval {
                    my $acc = $+{acc};
                    my $amount = $+{amount};
                    my ($is_virtual, $vmb);
                    if ($acc =~ s/^\((.+)\)$/$1/) {
                        $is_virtual = 1;
                    } elsif ($acc =~ s/^\[(.+)\]$/$1/) {
                        $is_virtual = 1;
                        $vmb = 1;
                    }
                    $p = Ledger::Posting->new(
                        account => $acc, amount => $amount,
                        is_virtual => $is_virtual,
                        virtual_must_balance => $vmb,
                        tx => $tx,
                        _line => $i);
                };
                die "Can't parse posting on line $i: $@" if $@;
                push @{$tx->postings}, $p;
            } else {
                $self->_add_tx($tx);
                $tx = undef;
                goto
            }
        } else {
    }
    $self->_add_tx($tx) if $tx;

    $log->tracef('<- _parse(), elapsed time=%.3fs',
                 tv_interval($t0, [gettimeofday]));
}

sub get_transactions {
    my ($self, $crit) = @_;
    my @res;
    for my $e (@{$self->entries}) {
        next unless $e->isa("Ledger::Transaction");
        if ($crit) {
            next unless $crit->($e);
        }
        push @res;
    }
    \@res;
}

sub get_accounts {
}

1;
# ABSTRACT: Represent an Org document
__END__

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 ATTRIBUTES

=head2 raw_lines => ARRAY

Store the raw source lines.

=head2 entries => ARRAY

Transactions, pricing, and top-level entities.


=head1 METHODS

=for Pod::Coverage BUILD

=head2 new(raw_lines => [...])

Create object from string.

=head2 get_transactions([$criteria]) => \@tx

Return transaction objects. $criteria is optional, a coderef that can be used to
filter wanted transactions.

=cut
