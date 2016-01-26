package Ledger::Value::TaggedValue;
use Moose;
use namespace::sweep;
use Ledger::Value::SubType::TaggedValue;

extends 'Ledger::Value::MetaData';

with (
    'Ledger::Role::IsValue',
    );

has '+value' => (
    isa      => 'Ledger::Value::SubType::TaggedValue',
    required => 1,
    builder  => '_null_value',
    );

# after because we define the 'value' method with 'around'
with (
    'Ledger::Role::HaveSubValues',
    );

sub _null_value {
    my $self = shift;
    Ledger::Value::SubType::TaggedValue->new(
	'parent' => $self,
	);
}

1;
