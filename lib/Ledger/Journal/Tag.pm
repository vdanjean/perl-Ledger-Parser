package Ledger::Journal::Tag;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Journal::Element';

with (
    'Ledger::Role::Element::Layout::MultiLines::List',
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

has_value_directive 'tag';

has_value_separator_simple 'ws1';

has_value 'name' => (
    isa    => 'TagName',
    required => 1,
    );

sub load_values_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^tag/,
	'parse_line_re' => qr<
	     ^(?<directive>tag)
	     (?<ws1>\s+)
	     (?<name>.*\S)
	                    >x,
	'noaccept_error_msg' => "not a tag declaration",
	'accept_error_msg' => "invalid tag declaration (missing tag name?)",
	'parse_value_error_msg' => "invalid data in tag declaration",
	'store' => 'all',
	);
}

1;

######################################################################
package Ledger::Journal::Tag::Assert;
use Moose;
use namespace::sweep;

extends 'Ledger::Journal::Tag::Element';

with (
    'Ledger::Role::Element::SubDirective::IsAssert',
    );

1;

######################################################################
package Ledger::Journal::Tag::Check;
use Moose;
use namespace::sweep;

extends 'Ledger::Journal::Tag::Element';

with (
    'Ledger::Role::Element::SubDirective::IsCheck',
    );

1;
