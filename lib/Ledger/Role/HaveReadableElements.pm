package Ledger::Role::HaveReadableElements;
use Moose::Role;
use namespace::sweep;
use TryCatch;
use Ledger::Util qw(indent);

with ('Ledger::Role::Readable');

requires '_readEnded';

binmode(STDERR, ":utf8");

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
	#print "Trying all kinds in ".$self->meta->name."\n";
	#print "Trying all kinds in ".$self->meta->name." for ".$reader->next_line;
	last LINE if not defined($reader->next_line);
	last LINE if $self->_readEnded($reader);
	$aborted=0;
	while (my $kind=shift @elementKinds) {
	    my $elem=undef;
	    try {
		#print "Trying kind $kind\n";
		$elem = "$kind"->new(
		    parent => $self,
		    reader => $reader);
		#print "Adding kind $kind\n";
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
	    print STDERR $errors[0]->parser_prefix."error: ".
		indent(' ', $errors[0]->message)."\n";
	} else {
	    $reader->pop_line;
	    print STDERR $errors[0]->parser_prefix.
		"error: invalid line while reading ".$self->meta->name.":\n ".
		$errors[0]->line.
		" * ".join("\n * ",
			  (map {
			      indent('   ', $_->message)
			   } @errors))."\n";
	}
    }
    #print "Parsing done in ".$self->meta->name."\n";
}

1;
