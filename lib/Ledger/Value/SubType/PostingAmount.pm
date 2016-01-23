package Ledger::Value::SubType::PostingAmount;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::sweep;
use Math::BigRat;
use Ledger::Util::ValueAttribute;

with (
    'Ledger::Role::HaveParent',
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

sub cleanup {}

1;
