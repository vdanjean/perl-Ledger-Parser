package Ledger::Journal::Blank;
use Moose;
use namespace::sweep;
use Ledger::Exception::ParseError;

with (
    'Ledger::Role::Element::Layout::OneLine',
    );

extends 'Ledger::Journal::Element';

sub load_values_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_line_re' => qr/^\s*/,
	'parse_line_re' => qr/^\s*/,
	'noaccept_error_msg' => "not a blank line",
	);
};

1;
