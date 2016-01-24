package Ledger::Journal::Note;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

with (
    'Ledger::Role::HaveCachedText',
    'Ledger::Role::Readable',
    );

extends 'Ledger::Journal::Element';

has_value 'commentchar' => (
    isa           => 'StrippedStr',
    required      => 1,
    default       => ';',
    );

has_value 'ws1' => (
    isa              => 'WS0',
    required         => 1,
    reset_on_cleanup => 1,
    default          => ' ',
);

has_value 'comment' => (
    isa    => 'EndStrippedStr',
);

sub load_from_reader {
    my $self = shift;
    my $reader = shift;

    my $line = $reader->pop_line;
    if ($line !~ /^([;#%|*])(\s*)(.*?)(\R?)\z/) {
	$reader->give_back_next_line($line);
	die Ledger::Exception::ParseError->new(
	    'line' => $line,
	    'parser_prefix' => $reader->error_prefix,
	    'message' => "not a comment line",
	    );
    }
    $self->commentchar($1);
    $self->ws1($2);
    $self->comment($3);
    $self->_cached_text($line);
};

sub compute_text {
    my $self = shift;
    return $self->commentchar.$self->ws1.$self->comment."\n";
}

1;
