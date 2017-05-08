package Ledger::Value::SubType::NoNote;
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
    #format_type => 'skip',
);

sub compute_text {
    my $self = shift;
    
    return '';
}

sub parse_str {
    my ($self, $str) = @_;

    $self->die_bad_string(
	$str,
	'invalid comment syntax!!! (internal error)')
	unless $str =~ /\A(
            ([\s]*)                         # 2) spaces
            )\z/x;

}

1;
