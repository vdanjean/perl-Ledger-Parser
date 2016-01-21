package Ledger::Value;
use Moose;
use namespace::sweep;
use Ledger::Exception::ValueParseError;

sub validate {
    return 1;
}

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

1;
