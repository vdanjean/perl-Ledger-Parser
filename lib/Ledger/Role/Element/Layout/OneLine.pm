package Ledger::Role::Element::Layout::OneLine;
use Moose::Role;
use namespace::sweep;

with (
    'Ledger::Role::Element::Layout::Base',
    # allows to iterate on values
    'Ledger::Role::Iterator::Elements' => {
	-alias  => { 
	    'getElementsIterator' => 'iterator',
	    'getValuesElementsIterator' => 'valuesIterator',
	},
    },
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

sub _iterable_elements {
    my $self = shift;
    return ();
}

1;
