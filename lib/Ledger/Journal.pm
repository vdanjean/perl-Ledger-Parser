package Ledger::Journal;

use 5.010;
use locale;
use Array::Iterator;
use Log::Any '$log';
use Moo;
use Ledger::Comment;
use Ledger::Posting;
use Ledger::Pricing;
use Ledger::Transaction;
use Ledger::Util;
use List::Util qw(min max);
use Time::HiRes qw(gettimeofday tv_interval);

# VERSION

has raw_lines => (is => 'rw');
has entries   => (is => 'rw'); # array of L::Transaction, L::Comment, ...
has _filename => (is => 'rw'); # location for parsing error message
has _lineno   => (is => 'rw'); # idem

my $re_line      = qr/^(?:(?<tx>\d)|
                          (?<pricing>P)|
                          (?<comment>.?))/x;
my $re_tx        = qr/^(?<date>$re_date)
                      (\s+\((?<seq>\d+)\))?
                      (?:\s+(?<desc>.+?)
                          (?:\s\s+;(?<comment>.*))?)?/x;
my $re_idcomment = qr/^\s+;/x;
my $re_identline = qr/^\s+(?:(?<comment>;)|(?<posting>.?))/x;
my $re_posting   = qr/^\s+(?<acc>$re_account)
                      (?:\s{2,}(?<amount>$re_amount))?
                      \s*(?:;(?<comment>.*))?$/x;
my $re_pricing   = qr/^P\s+ ($re_cmdity) \s+ $re_number \s+ ($re_cmdity)
                      (?:\s;(?<comment>.*))?\s*$/x;

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

sub _die {
    my ($self, $msg0) = @_;
    $msg0 .= "\n" unless $msg0 =~ /\n\z/;
    my $lineno = $self->_lineno;
    my $msg = join(
        "",
        "Ledger parse error",
        (defined($self->_filename) ? " in file ".$self->_filename : ""),
        (defined($lineno) ? " at line #$lineno" : ""),
        ": $msg0",
    );

    my $context = 2;
    if (defined $lineno) {
        for (max(0, $lineno-1-$context) ..
                 min(scalar(@{$self->raw_lines})-1, $lineno-1+$context)) {
            $msg .= ($_ == $lineno-1 ? "> " : "  ") . $self->raw_lines->[$_];
        }
    }

    die $msg;
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
    my $i;
    while (defined(my $line = $ll->get_next)) {
        $i = $ll->current_index;
        $self->_lineno($i+1);
        $log->tracef("Read line #%d: %s", $i+1, $line);
        $line =~ $re_line or $self->_die("Can't be parsed");

        if (defined $+{comment}) {
            $log->tracef("Line is a comment");

            my $ls = $i;
            while (1) {
                $line = $ll->peek;
                last unless defined($line);
                last unless $line =~ $re_comment;
                $ll->next;
                # should update _lineno, but not used here
            }
            my $le = $i;
            $log->tracef("Collected comment lines: %s", [@{$rl}[$ls..$le]]);
            my $c = Ledger::Comment->new(
                    parent => $self, line_start => $ls, line_end => $le);
            push @{$self->entries}, $c;

        } elsif (defined $+{tx}) {
            $log->tracef("Line is a transaction");

            $self->_die("Invalid transaction syntax") unless $line =~ $re_tx;
            my $tx;
            eval {
                $tx = Ledger::Transaction->new(
                    date => $+{date}, seq => $+{seq}, description=>$+{desc},
                    lineref => \$rl->[$i], journal => $self,
                );
            };
            $self->_die("Can't parse transaction: $@") if $@;
            while (1) {
                $line = $ll->peek;
                last if !defined($line);
                last unless $line =~ /^[ \t]/;
                $ll->next;
                $self->_lineno($ll->current_index + 1);
                $log->tracef("line(tx) = %s", $line);
                $self->_die("Can't be parsed") unless $line =~ $re_identline;
                if ($+{comment}) {

                    my $ls = $i;
                    while (1) {
                        $line = $ll->peek;
                        last unless defined($line);
                        last unless $line =~ $re_idcomment;
                        $ll->next;
                    }
                    my $le = $i;
                    $log->tracef("Found comment in tx: %s", @{$rl}[$ls..$le]);
                    my $c = Ledger::Comment->new(
                        parent => $tx, linerefs => [map {\$rl->[$_]} $ls..$le]);
                    push @{$tx->entries}, $c;

                } elsif ($+{posting}) {

                    $self->_die("Invalid posting syntax")
                        unless $line =~ $re_posting;
                    $log->tracef("Found posting: %s", $line);
                    my $p;
                    eval {
                        my $acc = $+{acc};
                        my $amount = $+{amount};
                        my $comment = $+{comment};
                        my ($is_virtual, $vmb);
                        if ($acc =~ s/^\((.+)\)$/$1/) {
                            $is_virtual = 1;
                        } elsif ($acc =~ s/^\[(.+)\]$/$1/) {
                            $is_virtual = 1;
                            $vmb = 1;
                        }
                        #$log->tracef("Amount = %s, parsed = %s", $amount,
                        #             Ledger::Util::parse_amount($amount))
                        #    if $amount;
                        $p = Ledger::Posting->new(
                            account => $acc, amount => $amount,
                            comment => $comment, is_virtual => $is_virtual,
                            virtual_must_balance => $vmb,
                            tx => $tx, lineref => \$rl->[$i]);
                    };
                    $self->_die("Can't parse posting: $@") if $@;
                    push @{$tx->entries}, $p;

                }
            }
            $tx->check;
            push @{$self->entries}, $tx;
        } elsif (defined $+{pricing}) {
            $log->tracef("Line is a pricing");

            $self->_die("Invalid pricing syntax") unless $line =~ $re_pricing;
            my $tx;
            eval {
                $tx = Ledger::Pricing->new(
                    date => $+{date}, seq => $+{seq}, description=>$+{desc},
                    comment => $+{comment},
                    lineref => \$rl->[$i], journal => $self,
                );
            };
            $self->_die("Can't parse transaction: $@") if $@;

        } else {
            $self->_die("Unknown entity");
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
