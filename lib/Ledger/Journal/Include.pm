package Ledger::Journal::Include;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

with (
    'Ledger::Role::HaveCachedText',
    'Ledger::Role::Readable',
    );

extends 'Ledger::Journal::Element';

has_value 'keyword' => (
    isa      => 'Constant',
    default  => 'include',
    );

has_value 'ws1' => (
    isa      => 'WS1',
    required  => 1,
    reset_on_cleanup => 1,
    default          => ' ',
    );

has_value 'file' => (
    isa      => 'File',
    required => 1,
    );

sub load_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^include/,
	'parse_line_re' => qr<
	     ^(?<keyword>include)
	     (?<ws1>\s+)
	     (?<file>.*\S)             
	                    >x,
	'noaccept_error_msg' => "not a include line",
	'accept_error_msg' => "invalid include line (missing file name?)",
	'store' => 'all',
	);

    $self->journals->add_journal(
	'reader' => $reader->newSubReader(
	    'file' => $self->file,
	),
	);
};

sub compute_text {
    my $self = shift;
    return $self->keyword_str.$self->ws1_str.$self->file_str."\n";
}

1;
