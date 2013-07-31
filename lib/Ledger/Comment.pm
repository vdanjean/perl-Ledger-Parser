package Ledger::Comment;

use 5.010;
use Log::Any '$log';
use Moo;

# VERSION

has linerefs => (is => 'rw', default=>sub { [] });
has parent   => (is => 'rw');

sub BUILD {
    my ($self, $args) = @_;
xo}

sub as_string {
    my ($self) = @_;
    join "", map { $$_ } @{$self->linerefs};
}

1;
# ABSTRACT: Represent comment or other non-parsable lines
__END__

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 ATTRIBUTES

=head2 parent => OBJ

Pointer to L<Ledger::Journal> or L<Ledger::Transaction> object.

=head2 linerefs => [REF TO STR, ...]


=head1 METHODS

=head2 new(...)

=head2 $c->as_string()

=cut
