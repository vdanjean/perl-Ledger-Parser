package Ledger::Transaction::Tag;
use Moose;
use namespace::sweep;

with (
    'Ledger::Role::IsTag',
    );

extends 'Ledger::Transaction::Element';

1;

