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

    my $state = shift;
    $state =~ s/\s//g;
    if (Ledger::Transaction::State->isSymbol($state)) {
	$state=Ledger::Transaction::State->fromSymbol($state);
    }
    return $self->$orig($state);
};

1;
