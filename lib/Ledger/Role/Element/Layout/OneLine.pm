package Ledger::Role::Element::Layout::OneLine;
use Moose::Role;
use namespace::sweep;

with (
    'Ledger::Role::Element::Layout::Base',
    );

sub load_from_reader {
    my $self = shift;
    my $reader = shift;
    return $self->load_values_from_reader($reader);
}

sub as_string {
    my $self=shift;
    return $self->gettext;
}

1;
