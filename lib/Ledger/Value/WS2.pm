package Ledger::Value::WS2;
use Moose;
use namespace::sweep;

extends 'Ledger::Value::WS';

around 'value' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig()
	unless @_;

    my $ws = shift;

    $self->die_bad_string(
	$ws,
	'invalid hard white space')
	unless $ws =~ m/^\s*(\t|  )\s*$/;
    return $self->$orig($ws);
};


1;
