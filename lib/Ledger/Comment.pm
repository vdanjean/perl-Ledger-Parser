package Ledger::Comment;

use 5.010;
use Log::Any '$log';
use Moo;

# VERSION

has line_start => (is => 'rw');
has line_end   => (is => 'rw');
has parent      => (is => 'rw');

sub BUILD {
    my ($self, $args) = @_;
}

sub as_string {
    my ($self) = @_;
    my $par = $self->parent;
    my $rl = $par->can("raw_lines") ? $par->raw_lines :
        $par->journal->raw_lines;

    join "", @{$rl}[ $self->line_start .. $self->line_end ];
}

1;
# ABSTRACT: Represent comment or other non-parsable lines
__END__

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 ATTRIBUTES

=head2 parent => OBJ

Pointer to L<Ledger::Journal> or L<Ledger::Transaction> object.

=head2 line_start => INT

=head2 line_end => INT


=head1 METHODS

=head2 new(...)

=head2 $c->as_string()

=cut
