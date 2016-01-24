package Ledger::Value::SubType::TaggedValue;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Value::SubType::MetaDataBase';

with (
    'Ledger::Role::IsSubValue',
    );

has_value 'ws1' => (
    isa              => 'WS0',
    required         => 1,
    reset_on_cleanup => 1,
    default          => ' ',
);

has_value 'name' => (
    isa    => 'StrippedStr',
);

has_value 'ws2' => (
    isa              => 'WS1',
    required         => 1,
    reset_on_cleanup => 1,
    default          => ' ',
);

has_value 'value' => (
    isa     => 'StrippedStr',
    default => '',
);

sub compute_text {
    my $self = shift;
    my $value=$self->value_str;
    if ($value ne '') {
	$value = $self->ws2_str.$value;
    }
    
    return $self->ws1_str.$self->name_str.":".$value;
}

sub parse_str {
    my ($self, $str) = @_;

    $self->die_bad_string(
	$str,
	'invalid Valued Tag syntax')
	unless $str =~ /\A(
            (\s*)                        # 2) ws1
            (\S+):                       # 3) tag name
            (?:(\s+)                     # 4) ws2
	    (.*))?                       # 5) tag value
            )\z/x;

    $self->ws1_str($2);
    $self->name_str($3);
    $self->ws2_str($4) if defined($4);
    $self->value_str($5) if defined($5);
}

1;
