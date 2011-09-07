package Ledger::Posting;

use 5.010;
use Log::Any '$log';
use Moo;

# VERSION

has account => (is => 'rw');
has amount => (is => 'rw');
has commodity => (is => 'rw');
has tx => (is => 'rw');

sub BUILD {
    my ($self, $args) = @_;
}

sub as_string {
    my ($self) = @_;
    $self->date->ymd . " " . ($self->description // "") . "\n" .
        join("", map {$_->as_string} @{$self->postings});
}

sub seq {
    # XXX
}

1;
# ABSTRACT: Represent a Ledger posting in a transaction
__END__

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 ATTRIBUTES

=head2 account => STR

=head2 amount => NUM

=head2 commodity => STR

=head2 tx => OBJECT

Pointer to transaction object.


=head1 METHODS

=for Pod::Coverage BUILD

=head2 seq()

Sequence of this posting in the transaction (1 for first, 2 for second, and so
on).

=head2 as_string()

=cut
