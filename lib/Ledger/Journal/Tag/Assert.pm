package Ledger::Journal::Tag::Assert;
use Moose;
use namespace::sweep;

extends 'Ledger::Journal::Tag::Element';

with (
    'Ledger::Role::SubDirective::IsAssert',
    );

1;
