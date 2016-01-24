package Ledger::Role::IsSubValue;
use Moose::Role;
use namespace::sweep;

requires 'parse_str';

with (
    'Ledger::Role::HaveParent',
    'Ledger::Role::ParseValue',
    );

sub cleanup {}

1;
