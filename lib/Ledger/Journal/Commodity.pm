package Ledger::Journal::Commodity;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Journal::Element';

with (
    'Ledger::Role::Element::Layout::OneLine',
    );

has_value_directive 'commodity';

has_value_separator_simple 'ws1';

has_value 'name' => (
    isa    => 'CommodityName',
    required => 1,
    );

sub load_values_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^commodity/,
	'parse_line_re' => qr<
	     ^(?<directive>commodity)
	     (?<ws1>\s+)
	     (?<name>.*\S)
	                    >x,
	'noaccept_error_msg' => "not a commodity declaration",
	'accept_error_msg' => "invalid commodity declaration (missing commodity name?)",
	'parse_value_error_msg' => "invalid data in commodity declaration",
	'store' => 'all',
	);
};

1;
