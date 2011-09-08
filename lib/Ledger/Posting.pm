package Ledger::Posting;

use 5.010;
use Log::Any '$log';
use Moo;

# VERSION

my $reset_line = sub { $_[0]->_line(undef) };

has account => (is => 'rw', trigger => $reset_line);
has amount => (is => 'rw', trigger => $reset_line); # [scalar, unit]
has is_virtual => (is => 'rw', trigger => $reset_line);
has virtual_must_balance => (is => 'rw', trigger => $reset_line);
has tx => (is => 'rw');
has _line => (is => 'rw');

sub BUILD {
    my ($self, $args) = @_;
}

sub as_string {
    my ($self) = @_;
    if (defined $self->_line) {
        $self->tx->journal->raw_lines->[ $self->_line ];
    } else {
        my ($o, $c);
        if ($self->is_virtual) {
            if ($self->virtual_must_balance) {
                ($o, $c) = ("[", "]");
            } else {
                ($o, $c) = ("(", ")");
            }
        } else {
            ($o, $c) = ("", "");
        }
        my $c;

        " $o".$self->account.$c.
            ($self->amount ? "  ".$self->format_amount() : "").
                "\n";
    }
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
