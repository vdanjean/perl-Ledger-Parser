package Ledger::Role::IsNote;
use Moose::Role;
use namespace::sweep;

with ('Ledger::Role::HaveCachedText',
      'Ledger::Role::Readable',
    );

has '_start' => (
    is       => 'rw',
    isa      => 'Str',
    default  => '    ',
    trigger  => \&_note_clear_cached_text,
    );

has 'comment_char' => (
    is       => 'rw',
    isa      => 'Str',
    default  => ';',
    trigger  => \&_note_clear_cached_text,
    );

before 'comment_char' => sub {
    my $self = shift;
    return unless @_;
    my $char = shift;
    my $RE_comment_char=$self->_RE_comment_char;
    
    if ($char !~ /^$RE_comment_char$/) {
	die "Invalid char comment '$char' to introduce comment in a '".
	    $self->parent->meta->name."' object";
    }
};

has 'note' => (
    is       => 'rw',
    isa      => 'Str',
    default  => '',
    trigger  => \&_note_clear_cached_text,
    );

around 'note' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig()
	unless @_;

    my $msg = shift;
    $msg =~ s/\s*$//; # remove blank at the end
    $msg =~ s/^(\S)/ $1/; # add a space if no blank at start
    return $self->$orig($msg);
};

sub _note_clear_cached_text {
    my $self = shift;
    return $self->_clear_cached_text(@_);
}

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
    if ($line !~ /^($RE_before_comment)($RE_comment_char)(.*?)(\R?)\z/) {
	$reader->give_back_next_line($line);
	die Ledger::Exception::ParseError->new(
	    'line' => $line,
	    'parser_prefix' => $reader->error_prefix,
	    'message' => "not a comment line",
	    );
    }
    $self->_start($1);
    $self->comment_char($2);
    $self->note($3);
    $self->_cached_text($line);
};

sub compute_text {
    my $self = shift;
    return $self->_start.$self->comment_char.$self->note."\n";
}

1;

