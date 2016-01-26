package Ledger::Journal::Tag::Check;
use Moose;
use namespace::sweep;

extends 'Ledger::Journal::Tag::Element';

with (
    'Ledger::Role::SubDirective::IsCheck',
    );

1;
