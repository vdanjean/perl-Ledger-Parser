package Ledger::Journal::Blank;
use Moose;
use namespace::sweep;

with (
    'Ledger::Role::HaveCachedText',
    'Ledger::Role::ReadableFromParser',
    );

extends 'Ledger::Journal::Element';

sub new_from_parser {
    my $class = shift;
    my %attr = @_;
    my $parser = $attr{'parser'};
    
    my $line = $parser->next_line;
    if ($line !~ /\S/) {
	return $class->new(@_);
    }
    
    return undef;
}

sub load_from_parser {
    my $self = shift;
    my $parser = shift;

    my $line = $parser->pop_line;
    if ($line !~ /\S/) {
	$self->_cached_text($line);
    } else {
	$parser->give_back_next_line($line);
	die $parser->error_prefix." cannot read a blank here";
    }
};

sub compute_text {
    my $self = shift;
    return "\n";
}

1;
