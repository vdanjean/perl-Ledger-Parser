package Ledger::Value::TagName;
use Moose;
use namespace::sweep;

extends 'Ledger::Value::Str';

around 'value' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig()
	unless @_;

    my $msg = shift;
    $msg =~ s/^\s*//;
    $msg =~ s/\s*$//;
    if ($msg =~ /\s/) {
	die Ledger::Exception::ValueParseError->new(
	    'message' => "Invalid tag name '$msg'",
	    );
    }
    return $self->$orig($msg);
};


1;
