package Ledger::Role::IsNote;
use Moose::Role;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

with (
    'Ledger::Role::HaveCachedText',
    'Ledger::Role::Readable',
    'Ledger::Role::HaveValues',
    );

has_value 'ws1' => (
    isa      => 'WS1',
    required => 1,
    default  => '    ',
    reset_on_cleanup => 1,    
    );

has_value 'note' => (
    isa      => 'MetaData',
    );

sub _RE_comment_char {
    my $self = shift;
    if ($self->parent->isa('Ledger::Journal')) {
	return qr@(?:[;#%|*])@;
    }
    return qr@(?:;)@;
}

sub _RE_before_comment {
    my $self = shift;
    if ($self->parent->isa('Ledger::Journal')) {
	return qr@(?:)@;
    }
    return qr@(?:\s+)@;
}

sub load_from_reader {
    my $self = shift;
    my $reader = shift;

    my $line = $reader->pop_line;
    my $RE_comment_char=$self->_RE_comment_char;
    my $RE_before_comment=$self->_RE_before_comment;
    if ($line !~ /^(\s+);(.*?)(\R?)\z/) {
	$reader->give_back_next_line($line);
	die Ledger::Exception::ParseError->new(
	    'line' => $line,
	    'parser_prefix' => $reader->error_prefix,
	    'message' => "not a comment line",
	    );
    }
    $self->ws1($1);
    $self->note($2);
    $self->_cached_text($line);
};

sub compute_text {
    my $self = shift;
    return $self->ws1_str.';'.$self->note_str."\n";
}

1;

