package Ledger::Value;
use Moose;
use namespace::sweep;
use Ledger::Exception::ValueParseError;

sub builder {
    my $class=shift;
    return $class->new(@_);
}

sub die_bad_string {
    my $self=shift;
    my $string=shift;
    my $msg=shift;

    die Ledger::Exception::ValueParseError->new(
	'message' => "'".$string."': ".$msg,
	);
}

sub element {
    my $self = shift;
    my $el = $self;

    while (!$el->isa('Ledger::Element')) {
	$el = $el->parent;
    }
    return $el;
}

1;
