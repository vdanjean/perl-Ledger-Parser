package Ledger::Pricing;

use 5.010;
use DateTime;
use Ledger::Util;
use Log::Any '$log';
use Moo;

# VERSION

has date        => (is => 'rw', trigger => $reset_lineref_sub);
has n           => (is => 'rw', trigger => $reset_lineref_sub);
has cmdity1     => (is => 'rw', trigger => $reset_lineref_sub);
has cmdity2     => (is => 'rw', trigger => $reset_lineref_sub);
has lineref     => (is => 'rw'); # ref to line in journal->lines
has journal     => (is => 'rw');

sub BUILD {
    my ($self, $args) = @_;
    if (!ref($self->date)) {
        $self->date(Ledger::Util::parse_date($self->date));
    }
    # re-set here because of trigger
    if (!defined($self->lineref)) {
        $self->lineref($args->{lineref});
    }
}

sub _die {
    my ($self, $msg) = @_;
    $self->journal->_die("Invalid pricing: $msg");
}

sub as_string {
    my ($self) = @_;

    defined($self->lineref) ?
        ${$self->lineref} :
            "P ". $self->date->ymd .
                $self->cmdity1 . " ". $self->n . $self->cmdity2 .
                    (defined $self->comment ? " ; ".$self->comment : "").
                        "\n";
}

1;
# ABSTRACT: Represent a Ledger pricing line
__END__

=for Pod::Coverage BUILD

=head1 SYNOPSIS


=head1 DESCRIPTION

A pricing in a ledger journal is of the form:

 P DATE cmdity1 N cmdity2

It asserts that commodity cmdity2 has a price of N cmdity2. Example:

 P 2011/10/17 USD 8500 IDR ; 1 US$ = 8500 Rp


=head1 ATTRIBUTES

=head2 date => DATETIME OBJ

=head2 cmdity1 => STR

=head2 n => NUM

=head2 cmdity2 => STR

=head2 comment => STR

=head2 lineref => REF TO STR

=head2 journal => OBJ

Pointer to L<Ledger::Journal> object.


=head1 METHODS

=head2 new(...)

=head2 $tx->as_string()

=cut
