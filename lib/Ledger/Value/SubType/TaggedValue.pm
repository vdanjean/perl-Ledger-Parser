package Ledger::Value::SubType::TaggedValue;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Value::SubType::MetaDataBase';

with (
    'Ledger::Role::IsSubValue',
    'Ledger::Role::HaveValues',
    );

has_value 'name' => (
    isa    => 'TagName',
);

has_value 'ws1' => (
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
	$value = $self->ws1_str.$value;
    }
    
    return $self->name_str.":".$value;
}

sub parse_str {
    my ($self, $str) = @_;

    $self->die_bad_string(
	$str,
	'invalid Valued Tag syntax')
	unless $str =~ /\A(
            (\S+):                       # 2) tag name
            (?:(\s+)                     # 3) ws1
	    (.*))?                       # 4) tag value
            )\z/x;

    $self->name_str($2);
    $self->ws1_str($3) if defined($3);
    $self->value_str($4) if defined($4);
}

###################################################################
# TAG management
with (
    'Ledger::Role::HaveTags',
    );

sub _collect_tags {
    my $self = shift;

    $self->_reset_tags;
    $self->_add_valued_tag($self->name_str, $self->value_str);
}

1;
