package Ledger::Value::PostingAmount;
use Moose;
use namespace::sweep;
use Ledger::Value::SubType::PostingAmount;

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

1;
