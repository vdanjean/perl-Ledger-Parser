package Ledger::Value::Str;
use Moose;
use namespace::sweep;

extends 'Ledger::Value';

with (
    'Ledger::Role::IsValue',
    );

has '+value' => (
    isa      => 'Str',
    );

sub _compute_text {
    my $self = shift;
    
    return $self->value;
}

sub validate {
    return 1;
}

1;
