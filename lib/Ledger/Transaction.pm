package Ledger::Transaction;

use 5.010;
use Log::Any '$log';
use Moo;
use DateTime;

# VERSION

has date => (is => 'rw');
has description => (is => 'rw');
has postings => (is => 'rw');

our $now     = DateTime->now;
our $re_date = qr!(?:(?<y>\d{2,4})[/-])?(?<m>\d{1,2})[/-](?<d>\d{1,2})!x;

sub _parse_date {
    my ($self, $s) = @_;
    die "Invalid date $s" unless $s =~ $re_date;
    my $y = $+{y} // $now->year;
    my $m = $+{m};
    my $d = $+{d};
    DateTime->new(year=>$y, month=>$m, day=>$d);
}

sub BUILD {
    my ($self, $args) = @_;

    my $date = $self->date;
    if ($date && !ref($date)) {
        $self->date($self->_parse_date($date));
    }
    if (!$self->postings) {
        $self->postings([]);
    }
}

sub as_string {
    my ($self) = @_;
    $self->date->ymd . " " . ($self->description // "") . "\n" .
        join("", map {$_->as_string} @{$self->postings});
}

1;
# ABSTRACT: Represent a Ledger transaction
__END__

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 ATTRIBUTES

=head2 date => DATETIME OBJECT

=head2 description => STR

=head2 postings => ARRAY OF OBJECTS

Array of L<Ledger::Posting> objects.


=head1 METHODS

=for Pod::Coverage BUILD

=head2 as_string()

=cut
