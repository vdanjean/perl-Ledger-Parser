package Ledger::Value::SubType::PlainNote;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Value::SubType::MetaDataBase';

with (
    'Ledger::Role::IsSubValue',
    );

has_value 'comment' => (
    isa    => 'StrippedStr',
    default => '',
);

sub compute_text {
    my $self = shift;
    
    return $self->comment;
}

sub parse_str {
    my ($self, $str) = @_;

    $self->die_bad_string(
	$str,
	'invalid comment syntax!!! (internal error)')
	unless $str =~ /\A(
            (.*)                         # 2) comment
            )\z/x;

    $self->comment($2);
}

1;
