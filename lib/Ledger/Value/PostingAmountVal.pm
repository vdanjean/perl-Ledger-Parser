package Ledger::Value::PostingAmountVal;
use Moose;
use namespace::sweep;
use Ledger::Types;
use Ledger::Util;

extends 'Ledger::Value';

with (
    'Ledger::Role::IsValue',
    );

has '+value' => (
    isa      => 'Ledger::Type::PostingAmount::Val',
    coerce   => 1,
    );

sub _compute_text {
    my $self = shift;

    return "".$self->value;
}

1;
