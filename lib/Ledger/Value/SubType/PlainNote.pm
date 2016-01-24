package Ledger::Value::SubType::PlainNote;
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

has_value 'comment' => (
    isa    => 'EndStrippedStr',
);

sub compute_text {
    my $self = shift;
    
    return $self->ws1.$self->comment;
}

sub parse_str {
    my ($self, $str) = @_;

    $self->die_bad_string(
	$str,
	'invalid comment syntax!!! (internal error)')
	unless $str =~ /\A(
            (\s*)                        # 2) ws1
            (.*)                         # 3) comment
            )\z/x;

    $self->ws1_str($2);
    $self->comment($3);
}

1;
