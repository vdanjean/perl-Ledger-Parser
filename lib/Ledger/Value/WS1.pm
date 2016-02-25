package Ledger::Value::WS1;
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
	'invalid non empty white space')
	unless $ws =~ m/^\s+$/;
    return $self->$orig($ws);
};


1;
