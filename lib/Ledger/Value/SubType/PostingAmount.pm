package Ledger::Value::SubType::PostingAmount;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::sweep;
use Math::BigRat;
use Ledger::Util::ValueAttribute;
use utf8;

with (
    'Ledger::Role::IsSubValue',
    );

has_value 'amount' => (
    isa    => 'PostingAmountVal',
    format_type => 'Num',
);

has_value 'commodity' => (
    isa    => 'StrippedStr',
);

sub compute_text {
    my $self = shift;
    my $postingFormat = $self->config->amount_format;
    my @formatParams=();

    push @formatParams, $self->formatValueParams();
    
    my $str=Ledger::Util->format(
	$postingFormat => {@formatParams}
	);
    if ($str->[0] != 200) {
	die($str->[1]);
    }
    $str->[1] =~ s/\s+$//;
    return $str->[1];
}

our $re_commodity = qr/[A-Z_]+[A-Za-z_]*|[\$£€¥]/;
our $RE_amount = qr/(-?)
                    ($re_commodity)?
                    (\s*) (-?[0-9,]+\.?[0-9]*)
                    (\s*) ($re_commodity)?
                   /x;

sub parse_str {
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
    $self->amount($num);
    $self->commodity($commodity1) if defined($commodity1);
    $self->commodity($commodity2) if defined($commodity2);
}

1;
