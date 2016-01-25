package Ledger::Value::EndStrippedStr;
use Moose;
use namespace::sweep;

extends 'Ledger::Value::Str';

around 'value' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig()
	unless @_;

    my $msg = shift;
    $msg =~ s/\s+$//;
    return $self->$orig($msg);
};


1;
