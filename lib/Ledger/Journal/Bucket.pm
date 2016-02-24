package Ledger::Journal::Bucket;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Journal::Element';

with (
    'Ledger::Role::Element::Layout::OneLine',
    );

has_value_directive 'bucket';

has_value_separator_simple 'ws1';

has_value 'name' => (
    isa    => 'AccountName',
    required => 1,
    );

sub load_values_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^bucket/,
	'parse_line_re' => qr<
	     ^(?<directive>bucket)
	     (?<ws1>\s+)
	     (?<name>.*\S)
	                    >x,
	'noaccept_error_msg' => "not a bucket declaration",
	'accept_error_msg' => "invalid bucket declaration (missing account name?)",
	'parse_value_error_msg' => "invalid data in bucket declaration",
	'store' => 'all',
	);
};

1;
