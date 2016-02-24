package Ledger::Value::Constant;
use Moose;
use namespace::sweep;

extends 'Ledger::Value::Str';

around 'value' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig()
	unless @_;

    my $msg = shift;
    $msg =~ s/^\s+//;
    $msg =~ s/\s+$//;
    $msg =~ s/\s+/ /g;
    if ($msg ne $self->default_value) {
	die Ledger::Exception::ValueParseError->new(
	    'message' => "Invalid value '$msg' for constant '".$self->default_value."'",
	    );
    }
    return $self->$orig($msg);
};

1;
