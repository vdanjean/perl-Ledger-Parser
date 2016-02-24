package Ledger::Journal::Python;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Journal::Element';

with (
    'Ledger::Role::Element::Layout::MultiLines::List',
    );

has '+elements' => (
    isa      => 'ArrayRef[Ledger::Journal::Python::Code]',
    );

sub _setupElementKinds {
    return [
	'Ledger::Journal::Python::Code',
	];
}

has_value_directive 'python';

sub load_values_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^python/,
	'parse_line_re' => qr<
	     ^(?<directive>python)
	                    >x,
	'noaccept_error_msg' => "not starting a python block",
	'accept_error_msg' => "invalid python line (garbage data?)",
	'store' => 'all',
	);
    return;
};

1;
######################################################################
package Ledger::Journal::Python::Code;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Element';

with (
    'Ledger::Role::Element::Layout::OneLine',
    );

has_value 'ws1' => (
    isa              => 'Str',
    required         => 1,
    reset_on_cleanup => 1,
    'default'        => "\t",
    );

has_value 'code' => (
    isa      => 'Str',
    );

sub load_values_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_re' => qr/^\s/,
	'parse_line_re' => qr /^
                (?<ws1>\s)
                (?<code>.*)
                           /x,
	'noaccept_error_msg' => "not a python code line",
	'accept_error_msg' => "invalid python code line",
	'store' => 'all',
	);
    return;
};

1;
