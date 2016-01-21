package Ledger::Value::TransactionState;
use Moose;
use namespace::sweep;
use Ledger::Transaction::State;
use Ledger::Types;

extends 'Ledger::Value';

with (
    'Ledger::Role::IsValue',
    );

has '+value' => (
    isa      => 'Ledger::Type::Transaction::State',
    );

sub _compute_text {
    my $self = shift;
    
    return Ledger::Transaction::State->toSymbol(
	$self->value
	);
}

around 'value' => sub {
    my $orig = shift;
    my $self = shift;
    
    return $self->$orig()
	unless @_;

    my $ret;
    my $state = shift;
    $state =~ s/\s//g;
    if (Ledger::Transaction::State->isSymbol($state)) {
	$state=Ledger::Transaction::State->fromSymbol($state);
	$ret=$self->$orig($state, 'clear_cache' => 0);
	$self->_cached_text($state);
    } else {
	$ret=$self->$orig($state);
    }
    return $ret;
};

1;
