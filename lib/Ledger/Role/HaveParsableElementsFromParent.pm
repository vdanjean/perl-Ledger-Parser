package Ledger::Role::HaveParsableElementsFromParent;
use Moose::Role;

with (
    'Ledger::Role::HaveParent',
    'Ledger::Role::HaveParsableElements',
    );

sub _listElementKinds {
    my $self = shift;
    return $self->parent->_listElementKinds;
}

1;
