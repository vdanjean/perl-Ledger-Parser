package Ledger::Role::HaveReadableElementsFromParent;
use Moose::Role;
use namespace::sweep;

with (
    'Ledger::Role::HaveParent',
    'Ledger::Role::HaveReadableElements',
    );

sub _listElementKindsOrig {
    my $self = shift;
    return $self->parent->_listElementKindsOrig;
}

sub _listElementKinds {
    my $self = shift;
    return (
	$self->parent->_listElementKindsOrig,
	$self->_listElementKindsAppend,
	);
}

1;
