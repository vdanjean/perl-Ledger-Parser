package Ledger::Role::IsReadableValue;
use Moose::Role;
use namespace::sweep;

with (
    'Ledger::Role::IsValue',
    );

requires 'parseValue';

1;
