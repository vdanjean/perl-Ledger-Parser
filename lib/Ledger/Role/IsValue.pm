package Ledger::Role::IsValue;
use Moose::Role;
use namespace::sweep;
use Ledger::Exception::Validation;

with (
    'Ledger::Role::IsValueBase',
    'Ledger::Role::HaveCachedText',
    );

sub value_str {
    my $self = shift;

    return $self->as_string unless @_;
    
    my $val = shift;
    my $ret = $self->value($val);
    $self->_cached_text($val);
    return $ret;
}

1;
