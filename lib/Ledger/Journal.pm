package Ledger::Journal;

use 5.010;
use locale;
use Array::Iterator;
use Log::Any '$log';
use Moo;
use Ledger::Transaction;
use Ledger::Posting;
#use Ledger::Pricing;
use Ledger::Comment;
use Time::HiRes qw(gettimeofday tv_interval);

# VERSION

has raw_lines => (is => 'rw');
has entries => (is => 'rw'); # either L::Transaction or L::Separator

my $re_line      = qr/^(?:(?<tx>\d)|
                          #(?<pricing>P)|
                          (?<comment>.?))/x;
my $re_date      = $Ledger::Transaction::re_date;
my $re_tx        = qr/^(?<date>$re_date)
                      (\s+\((?<seq>\d+)\))?
                      (?:\s+(?<desc>.+))?/x;
our $re_accpart   = qr/(?:(
                               (?:[^:\s]+[ \t][^:\s]*)|
                               [^:\s]+
                       ))+/x; # don't allow double space
our $re_acc0      = qr/(?:$re_accpart(?::$re_accpart)*)/x;
our $re_acc       = qr/(?<acc>$re_acc0|\($re_acc0\)|\[$re_acc0\])/x;
my $re_comment   = qr/^(\s*;|[^0-9P]|\s*$)/x;
my $re_idcomment = qr/^\s+;/x;
my $re_identline = qr/^\s+(?:(?<comment>;)|(?<posting>.?))/x;
my $re_amount    = $Ledger::Posting::re_amount;
my $re_posting   = qr/^\s+(?<acc>$re_acc)
                      (?:\s{2,}(?<amount>$re_amount))?
                      \s*(?:;.*)?$/x;
#my $re_pricing  = qr/^P\s+/x; # we don't parse it atm. (date)? cmd1 amount cmd2

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
    join "", map {$_->as_string} @{$self->entries};
}

sub _add_tx {
}

sub _parse {
    my ($self) = @_;
    $log->tracef('-> _parse()');
    my $t0 = [gettimeofday];

    my $rl = $self->raw_lines;
    my $ll = Array::Iterator->new($rl);
    while (defined(my $line = $ll->get_next)) {
        $log->tracef("line(0) = %s", $line);
        $line =~ $re_line or die "BUG: re_line doesn't match line #".
            ($ll->current_index+1).": $line";

        if (defined $+{comment}) {
            $log->tracef("Line is a comment");

            my $ls = $ll->current_index;
            while (1) {
                $line = $ll->peek;
                last unless defined($line);
                last unless $line =~ $re_comment;
                $ll->next;
            }
            my $le = $ll->current_index;
            $log->tracef("Collected comment lines: %s", [@{$rl}[$ls..$le]]);
            my $c = Ledger::Comment->new(
                    parent => $self, line_start => $ls, line_end => $le);
            push @{$self->entries}, $c;

        } elsif (defined $+{tx}) {
            $log->tracef("Line is a transaction");

            die "Invalid transaction syntax on line #".
                ($ll->current_index+1).": $line" unless $line =~ $re_tx;
            my $tx;
            eval {
                $tx = Ledger::Transaction->new(
                    date => $+{date}, seq => $+{seq}, description=>$+{desc},
                    line => $ll->current_index, journal => $self,
                );
            };
            die "Can't parse transaction on line #".($ll->current_index+1).
                ": $@" if $@;
            while (1) {
                $line = $ll->peek;
                last if !defined($line);
                last unless $line =~ /^[ \t]/;
                $ll->next;
                $log->tracef("line(tx) = %s", $line);
                die "BUG: re_identline doesn't match line #".
                    ($ll->current_index+1).": $line"
                        unless $line =~ $re_identline;
                if ($+{comment}) {

                    my $ls = $ll->current_index;
                    while (1) {
                        $line = $ll->peek;
                        last unless defined($line);
                        last unless $line =~ $re_idcomment;
                        $ll->next;
                    }
                    my $le = $ll->current_index;
                    $log->tracef("Found comment in tx: %s", @{$rl}[$ls..$le]);
                    my $c = Ledger::Comment->new(
                        parent => $tx, line_start => $ls, line_end => $le);
                    push @{$tx->entries}, $c;

                } elsif ($+{posting}) {

                    die "Invalid posting syntax on line #".
                        ($ll->current_index+1).": $line"
                            unless $line =~ $re_posting;
                    $log->tracef("Found posting: %s", $line);
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
                            line => $ll->current_index);
                    };
                    die "Can't parse posting on line ".$ll->current_index.
                        ": $@" if $@;
                    push @{$tx->entries}, $p;

                }
            }
            $tx->check;
            push @{$self->entries}, $tx;
        } else {
            die "BUG: unknown entity";
        }
    }

    $log->tracef('<- _parse(), elapsed time=%.3fs',
                 tv_interval($t0, [gettimeofday]));
}

sub transactions {
    my ($self, $crit) = @_;
    my @res;
    for my $e (@{$self->entries}) {
        next unless $e->isa("Ledger::Transaction");
        if ($crit) {
            next unless $crit->($e);
        }
        push @res, $e;
    }
    \@res;
}

sub accounts {
    my ($self) = @_;
    my %acc;
    for my $tx (@{$self->entries}) {
        next unless $tx->isa('Ledger::Transaction');
        for my $p (@{$tx->entries}) {
            next unless $p->isa('Ledger::Posting');
            $acc{$p->account}++;
        }
    }
    [keys %acc];
}

sub add_transaction {
    my ($self, $tx) = @_;
    push @{$self->{entries}}, $tx;
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

=head2 $journal->transactions([$criteria]) => \@tx

Return transaction objects. $criteria is optional, a coderef that can be used to
filter wanted transactions.

=head2 $journal->accounts() => \@acc

Return all accounts that are mentioned.

=head2 $journal->add_transaction($tx)


=head1 SEE ALSO

L<Ledger::Transaction>

=cut
