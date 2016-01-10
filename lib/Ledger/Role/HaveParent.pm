package Ledger::Role::HaveParent;
use Moose::Role;

has 'parent' => (
    is        => 'ro',
    isa       => 'Ledger::Role::HaveElements',
    required  => 1,
    weak_ref  => 1,
    );

1;

