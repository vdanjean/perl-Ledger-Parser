package Ledger::Value::CommodityName;
use Moose;
use namespace::sweep;
use Ledger::Util qw(:regexp);

extends 'Ledger::Value::Str';

my $re_commodity=re_commodity;

around 'value' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig()
	unless @_;

    my $msg = shift;
    $msg =~ s/^\s+//;
    $msg =~ s/\s+$//;
    if ($msg !~ /$re_commodity/) {
	die Ledger::Exception::ValueParseError->new(
	    'message' => "Invalid commodity name '$msg'",
	    );
    }
    return $self->$orig($msg);
};

1;
