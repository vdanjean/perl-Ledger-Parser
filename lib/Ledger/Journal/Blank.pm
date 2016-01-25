package Ledger::Journal::Blank;
use Moose;
use namespace::sweep;
use Ledger::Exception::ParseError;

with (
    'Ledger::Role::HaveCachedText',
    'Ledger::Role::Readable',
    );

extends 'Ledger::Journal::Element';

sub load_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_line_re' => qr/^\s*/,
	'parse_line_re' => qr/^\s*/,
	'noaccept_error_msg' => "not a blank line",
	);
};

sub compute_text {
    my $self = shift;
    return "\n";
}

1;
