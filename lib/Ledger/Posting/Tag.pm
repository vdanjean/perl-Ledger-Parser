package Ledger::Posting::Tag;
use Moose;
use namespace::sweep;

with (
    'Ledger::Role::IsTag',
    );

extends 'Ledger::Posting::Element';

has '+_start' => (
    default => '      ',
    );

1;
