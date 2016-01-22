package Ledger::Value::PostingAmount;
use Moose;
use namespace::sweep;
use Ledger::Types;
use Ledger::Util;
use Ledger::Types::PostingAmount;
use utf8;

extends 'Ledger::Value';

with (
    'Ledger::Role::IsValue',
    );

has '+value' => (
    isa      => 'Ledger::Types::PostingAmount',
    required => 1,
    default  => sub {
	my $self = shift;
	Ledger::Types::PostingAmount->new(
	    'parent' => $self,
	    );
    },
    );

sub _compute_text {
    my $self = shift;

    return $self->value->compute_text;
}

our $re_commodity = qr/[A-Z_]+[A-Za-z_]*|[\$£€¥]/;
our $RE_amount = qr/(-?)
                    ($re_commodity)?
                    (\s*) (-?[0-9,]+\.?[0-9]*)
                    (\s*) ($re_commodity)?
                   /x;

sub _parse_amount {
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


around 'value' => sub {
    my $orig = shift;
    my $self = shift;
    
    return $self->$orig()
	unless @_;
    
    my $amount = shift;
    if (ref(\$amount) eq "SCALAR") {
	# assuming a String we will try to convert
	$self->_parse_amount($amount);
	return ;
    }
    return $self->$orig($amount);
};

before 'cleanup' => sub {
    my $self = shift;
    $self->value->cleanup(@_);
};

1;
