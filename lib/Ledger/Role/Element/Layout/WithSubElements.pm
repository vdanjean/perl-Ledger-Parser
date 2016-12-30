package Ledger::Role::Element::Layout::WithSubElements;
use Moose::Role;
use namespace::sweep;

requires 'load_from_reader';

with (
    'Ledger::Role::Element::Layout::Base',
    'Ledger::Role::Readable',
    'Ledger::Role::HaveReadableElements',    
    );

sub as_string {
    my $self = shift;
    return $self->gettext
	.$self->_as_string_elements;
}

before 'load_from_reader' => sub {
    my $self = shift;
    my $reader = shift;
    $self->load_values_from_reader($reader);
    return;
};

1;
