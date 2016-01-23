package Ledger::Value::PostingAmount;
use Moose;
use namespace::sweep;
use Ledger::Types;
use Ledger::Util;
use Ledger::Value::SubType::PostingAmount;
use utf8;

extends 'Ledger::Value';

with (
    'Ledger::Role::IsValue',
    );

has '+value' => (
    isa      => 'Ledger::Value::SubType::PostingAmount',
    required => 1,
    builder  => '_null_value',
    );

# after because we define the 'value' method with 'around'
with (
    'Ledger::Role::HaveSubValues',
    );

sub _null_value {
    my $self = shift;
    return Ledger::Value::SubType::PostingAmount->new(
	'parent' => $self,
	);
}

our $re_commodity = qr/[A-Z_]+[A-Za-z_]*|[\$£€¥]/;
our $RE_amount = qr/(-?)
                    ($re_commodity)?
                    (\s*) (-?[0-9,]+\.?[0-9]*)
                    (\s*) ($re_commodity)?
                   /x;

sub _parse_str {
    my ($self, $str) = @_;

    $self->die_bad_string(
	$str,
	'invalid amount syntax')
	unless $str =~ /\A(?:$RE_amount)\z/;

    my ($minsign, $commodity1, $ws1, $num, $ws2, $commodity2) =
        ($1, $2, $3, $4, $5, $6);
    if ($commodity1 && $commodity2) {
	$self->die_bad_string(
	    $str,
	    'invalid amount syntax (double commodity)');
    }
    $num =~ s/,//g;
    $num = Math::BigRat->new($num);
    $num = $num * -1 if $minsign;
    $self->value->amount($num);
    $self->value->commodity($commodity1) if defined($commodity1);
    $self->value->commodity($commodity2) if defined($commodity2);
}

1;
