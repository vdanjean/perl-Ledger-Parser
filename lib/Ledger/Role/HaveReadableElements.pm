package Ledger::Role::HaveReadableElements;
use Moose::Role;
use namespace::sweep;
use TryCatch;

with ('Ledger::Role::Readable');

requires '_readEnded';

sub load_from_reader {
    my $self = shift;
    my $reader = shift;
    my @elementKinds;
    my $e;
    my @errors;

  LINE:
    for(;;) {
	@elementKinds = $self->_listElementKinds;
	@errors=();
	#print "Trying all kinds in ".$self->meta->name."\n";
	last LINE if not defined($reader->next_line);
	last LINE if $self->_readEnded($reader);
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
		push @errors, $e;
		unshift @elementKinds, @{$e->suggestionTypes};
	    };
	    next LINE if defined($elem);
	}
	die $errors[0]->parser_prefix.
	    "cannot interpret the following line:\n".$reader->next_line.
	    "  * ".join("\n  * ",
		 (map { $_->message } @errors))."\n";
    }
    #print "Parsing done in ".$self->meta->name."\n";
}

1;
