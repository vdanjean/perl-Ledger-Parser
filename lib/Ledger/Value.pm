package Ledger::Value;
use Moose;
use namespace::sweep;
use Ledger::Exception::ValueParseError;

sub builder {
    my $class=shift;
    return $class->new(@_);
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
