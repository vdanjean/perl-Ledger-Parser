package Ledger::Journal;

use 5.010;
use locale;
use Log::Any '$log';
use Moo;
use Ledger::Transaction;
use Ledger::Posting;
#use Ledger::Pricing;
use Time::HiRes qw(gettimeofday tv_interval);

# VERSION

has raw_lines => (is => 'rw');
has transactions => (is => 'rw');

my $re_date    = $Ledger::Transaction::re_date;
my $re_tx      = qr/^(?<date>$re_date)
                    (\s+\(?<seq>\d+\)\s*)?
                    (?:\s+(?<desc>.+))?/x;
my $re_accpart = qr/(?:
                        [^:\s]+|
                        \s|
                        (?:[^:\s]+\s)+|
                        (?:\s[^:\s]+)+
                    )/x; # don't allow double space
my $re_posting = qr/^\s+$re_accpart/;
my $re_pricing = qr/^P\s+/x; # we don't parse it atm. (date)? cmd1 amount cmd2

sub BUILD {
    my ($self, $args) = @_;

    if (!$self->raw_lines) {
        $self->raw_lines([]);
    }
    if (!$self->transactions) {
        $self->transactions([]);
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

    my $i=0;
    my $tx;
    for my $line0 (@{$self->raw_lines}) {
        $i++;
        my $line = $line0; # let's not trample the orig array

        if ($tx) {
        } else {
            if ($line =~ $re_tx) {
                $tx = Ledger::Transaction->new(
                    date => $+{date}, seq => $+{seq}, description=>$+{desc},
                );
            } elsif ($line =~ $re_pricing) {
                #
            } else {
                # ignore line
            }
        }
    }

    $log->tracef('<- _parse(), elapsed time=%.3fs',
                 tv_interval($t0, [gettimeofday]));
}

1;
# ABSTRACT: Represent an Org document
__END__

=head1 SYNOPSIS

 use Org::Document;

 # create a new Org document tree from string
 my $org = Org::Document->new(from_string => <<EOF);
 * heading 1a
 some text
 ** heading 2
 * heading 1b
 EOF


=head1 DESCRIPTION



=head1 ATTRIBUTES

=head2 raw_lines => ARRAY

Store the raw source lines.

=head2 transactions => ARRAY

List transactions.

=head2 prices => ARRAY

List prices.


=head1 METHODS

=for Pod::Coverage BUILD

=head2 new(raw_lines => [...])

Create object from string.

=cut
