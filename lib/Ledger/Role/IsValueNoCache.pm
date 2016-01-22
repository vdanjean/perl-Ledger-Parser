package Ledger::Role::IsValueNoCache;
use Moose::Role;
use namespace::sweep;
use Ledger::Exception::Validation;

with (
    'Ledger::Role::IsValueBase',
    );

sub value_str {
    my $self = shift;

    return $self->as_string unless @_;

    die "Internal error: a value without cache is not parsable";
}

sub as_string {
    my $self = shift;
    
    return $self->compute_text
}

1;
