package Ledger::Value::AccountName;
use Moose;
use namespace::sweep;
use Ledger::Util qw(:regexp);

extends 'Ledger::Value::Str';

my $re_account=re_account;

around 'value' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig()
	unless @_;

    my $msg = shift;
    $msg =~ s/^\s+//;
    $msg =~ s/\s+$//;
    if ($msg !~ /^$re_account$/) {
	die Ledger::Exception::ValueParseError->new(
	    'message' => "Invalid account name '$msg'",
	    );
    }
    return $self->$orig($msg);
};


1;
