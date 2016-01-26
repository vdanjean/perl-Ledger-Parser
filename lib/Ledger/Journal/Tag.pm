package Ledger::Journal::Tag;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Journal::Element';

with (
    'Ledger::Role::IsElementWithElements',
    );

has '+elements' => (
    isa      => 'ArrayRef[Ledger::Journal::Tag::Element]',
    );

sub _setupElementKinds {
    return [
	'Ledger::Journal::Tag::Check',
	'Ledger::Journal::Tag::Assert',
	];
}

has_value 'keyword' => (
    isa      => 'Constant',
    required => 1,
    default  => 'tag',
    );

has_value 'ws1' => (
    isa      => 'WS1',
    required  => 1,
    reset_on_cleanup => 1,
    default          => ' ',
    );

has_value 'name' => (
    isa    => 'TagName',
    required => 1,
    );

before 'load_from_reader' => sub {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^tag/,
	'parse_line_re' => qr<
	     ^(?<keyword>tag)
	     (?<ws1>\s+)
	     (?<name>.*\S)
	                    >x,
	'noaccept_error_msg' => "not a tag declaration",
	'accept_error_msg' => "invalid tag declaration (missing tag name?)",
	'parse_value_error_msg' => "invalid data in tag declaration",
	'store' => 'all',
	);
};

sub compute_text {
    my $self = shift;
    return $self->keyword_str.$self->ws1_str.$self->name_str."\n";
}

1;
