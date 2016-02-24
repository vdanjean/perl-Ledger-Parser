package Ledger::Journal::Include;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Journal::Element';

with (
    'Ledger::Role::Element::Layout::OneLine',
    );

has_value_directive 'include';

has_value_separator_simple 'ws1';

has_value 'file' => (
    isa      => 'File',
    required => 1,
    );

has 'incJournal' => (
    isa       => 'Ledger::Journal',
    is        => 'ro',
    writer    => '_setIncJournal',
    predicate => 'loaded',
    );

sub _loadIncJournal {
    my $self = shift;
    my $reader = shift;
    if (! $self->loaded) {
	$self->_setIncJournal(
	    $self->journals->add_journal(
		'reader' => $reader->newSubReader(
		    'file' => $self->file,
		),
	    ));
    }
}

sub load_values_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^include/,
	'parse_line_re' => qr<
	     ^(?<directive>include)
	     (?<ws1>\s+)
	     (?<file>.*\S)             
	                    >x,
	'noaccept_error_msg' => "not a include line",
	'accept_error_msg' => "invalid include line (missing file name?)",
	'store' => 'all',
	);

    $self->_loadIncJournal($reader);
};

1;
