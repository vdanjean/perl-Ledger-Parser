package Ledger::Role::IsTag;
use Moose::Role;
use namespace::sweep;

with ('Ledger::Role::HaveCachedText',
      'Ledger::Role::Readable',
    );

has '_start' => (
    is       => 'rw',
    isa      => 'Str',
    default  => '    ',
    trigger  => \&_tag_clear_cached_text,
    );

has 'name' => (
    is       => 'rw',
    isa      => 'Str',
    default  => '',
    trigger  => \&_tag_clear_cached_text,
    );

has 'value' => (
    is       => 'rw',
    isa      => 'Str',
    default  => '',
    trigger  => \&_tag_clear_cached_text,
    );

around 'value' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig()
	unless @_;

    my $msg = shift;
    $msg =~ s/\s*$//; # remove blank at the end
    $msg =~ s/^(\S)/ $1/; # add a space if no blank at start
    return $self->$orig($msg);
};

sub _tag_clear_cached_text {
    my $self = shift;
    return $self->_clear_cached_text(@_);
}

# WARNING: can be called as a class method
# In this case, the 'parent' argument is mandatory
sub _RE_before_tag {
    my $self = shift;
    my $parent = shift // $self->parent;
    if ($parent->isa('Ledger::Journal')) {
	return qr@(?:)@;
    }
    return qr@(?:\s+)@;
}

sub load_from_reader {
    my $self = shift;
    my $reader = shift;

    my $line = $reader->pop_line;
    if ($line !~ /^(\s+);(?:\s*)([^\s:]+):\s(.*?)(\R?)\z/) {
	$reader->give_back_next_line($line);
	die Ledger::Exception::ParseError->new(
	    'line' => $line,
	    'parser_prefix' => $reader->error_prefix,
	    'message' => "not a tag line",
	    );
    }
    $self->_start($1);
    $self->name($2);
    $self->value($3);
    $self->_cached_text($line);
};

sub compute_text {
    my $self = shift;
    return $self->_start."; ".$self->name.': '.$self->value."\n";
}

1;
