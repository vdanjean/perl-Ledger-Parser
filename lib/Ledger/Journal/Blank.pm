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

    my $line = $reader->pop_line;
    if ($line !~ /\S/) {
	$self->_cached_text($line);
    } else {
	$reader->give_back_next_line($line);
	die Ledger::Exception::ParseError->new(
	    'line' => $line,
	    'parser_prefix' => $reader->error_prefix,
	    'message' => "not a blank line",
	    );
    }
};

sub compute_text {
    my $self = shift;
    return "\n";
}

1;
