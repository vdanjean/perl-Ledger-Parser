package Ledger::Value::SubType::PostingAccount;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::sweep;
use Math::BigRat;
use Ledger::Util::ValueAttribute;

with (
    'Ledger::Role::HaveParent',
    );

has_value 'name' => (
    isa    => 'StrippedStr',
    required => 1,
    format_type => 'skip',
);

has 'kind' => (
    is       => 'rw',
    isa      => 'Ledger::Type::Posting::Kind',
    default  => Ledger::Posting::Kind::REAL,
    trigger  => sub {
	my $self=shift;
	$self->_value_updated(@_);
    },
    );

sub compute_text {
    my $self = shift;

    return Ledger::Posting::Kind->formatAccount(
	$self->kind,
	$self->name_str,
	);
    
    my $postingFormat = '@{name:%s}'; #$self->config->account_format;
    my @formatParams=();

    push @formatParams, $self->formatValueParams();
    
    push @formatParams, Ledger::Util->buildFormatParam(
	'name',
	'object' => $self,
	'value' => Ledger::Posting::Kind->formatAccount(
	    $self->kind,
	    $self->name_str,
	),
	);

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
