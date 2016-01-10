package Ledger::Posting::Note;
use Moose;
use namespace::sweep;

with ('Ledger::Role::HaveCachedText',
      'Ledger::Role::ReadableFromParser',
    );

extends 'Ledger::Posting::Element';

has 'start' => (
    is       => 'rw',
    isa      => 'Str',
    default  => '    ',
    trigger  => \&_clear_cached_text,
    );

has 'message' => (
    is       => 'rw',
    isa      => 'Str',
    default  => '',
    trigger  => \&_clear_cached_text,
    );

around 'message' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig()
	unless @_;

    my $msg = shift;
    $msg =~ s/\s*$//;
    return $self->$orig($msg);
};

sub new_from_parser {
    my $class = shift;
    my %attr = @_;
    my $parser = $attr{'parser'};
    
    my $line = $parser->next_line;
    if ($line =~ /^(\s+);/) {
	return $class->new(@_);
    }
    
    return undef;
}

sub load_from_parser {
    my $self = shift;
    my $parser = shift;

    my $line = $parser->pop_line;
    if ($line =~ /^(\s+); ?(.*?)(\R?)\z/) {
	$self->start($1);
	$self->message($2);
	$self->_cached_text($line);
    } else {
	$parser->give_back_next_line($line);
	die $parser->error_prefix." cannot read a note here";
    }
};

sub compute_text {
    my $self = shift;
    return $self->start."; ".$self->message."\n";
}

1;
