package Ledger::Role::ParseValue;
use Moose::Role;
use namespace::sweep;

sub die_bad_string {
    my $self=shift;
    my $string=shift;
    my $msg=shift;

    die Ledger::Exception::ValueParseError->new(
	'message' => "'".$string."': ".$msg,
	);
}

1;

