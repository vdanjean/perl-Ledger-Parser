package Ledger::Role::HaveReadableElements;
use Moose::Role;
use namespace::sweep;
use TryCatch;
use Ledger::Util qw(indent);

my $DEBUG = 0;
sub debug {
    print $_[0], "\n";
}

with ('Ledger::Role::Readable');

requires '_readEnded';

sub load_from_reader {
    my $self = shift;
    my $reader = shift;
    my @elementKinds;
    my $e;
    my @errors;
    my $aborted;

  LINE:
    for(;;) {
	@elementKinds = $self->_listElementKinds;
	@errors=();
	debug "Trying all kinds in ".$self->meta->name." for ".($reader->next_line // '')
	    if $DEBUG;
	last LINE if $self->_readEnded($reader);
	$aborted=0;
	while (my $kind=shift @elementKinds) {
	    my $elem=undef;
	    try {
		debug "Trying kind $kind" if $DEBUG;
		$elem = "$kind"->new(
		    parent => $self,
		    reader => $reader);
		debug "Adding kind $kind" if $DEBUG;
		$self->_add_element($elem);
	    }
	    catch (Ledger::Exception::ParseError $e) {
		if ($e->abortParsing) {
		    @elementKinds=();
		    @errors=();
		    $aborted=1;
		}
		push @errors, $e;
		unshift @elementKinds, @{$e->suggestionTypes};
	    };
	    next LINE if defined($elem);
	}
	if ($aborted) {
	    $self->journal->addParseError(
		Ledger::Exception::ParseError->new(
		    'parser_prefix' => $errors[0]->parser_prefix,
		    'line' => $errors[0]->line,
		    'message' => ("error: ".
				  indent(' ', $errors[0]->message)),
		)
		);
	} else {
	    $reader->pop_line;
	    $self->journal->addParseError(
		Ledger::Exception::ParseError->new(
		    'parser_prefix' => $errors[0]->parser_prefix,
		    'line' => $errors[0]->line,
		    'message' => ("error: invalid line while reading ".
				  $self->meta->name.":\n ".
				  $errors[0]->line.
				  " * ".join("\n * ",
					     (map {
						 indent('   ', $_->message)
					      } @errors))),
		    ),
		);
	}
    }
    debug "Parsing done in ".$self->meta->name if $DEBUG;
}

1;
