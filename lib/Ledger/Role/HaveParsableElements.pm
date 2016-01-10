package Ledger::Role::HaveParsableElements;
use Moose::Role;
use namespace::sweep;

with ('Ledger::Role::ReadableFromParser');

requires '_parsingEnd';

sub load_from_parser {
    my $self = shift;
    my $parser = shift;
    my @elementKinds = $self->_listElementKinds;

  LINE:
    for(;;) {
	#print "Trying all kinds in ".$self->meta->name."\n";
	last LINE if not defined($parser->next_line);
	last LINE if $self->_parsingEnd($parser);
	for my $kind (@elementKinds) {
	    #print "Trying kind $kind\n";
	    my $elem = "$kind"->new_from_parser(
		parent => $self,
		parser => $parser);
	    if (defined($elem)) {
		$self->_add_element($elem);
		next LINE;
	    }
	}
	die $parser->error_prefix." in ".$self->meta->name.", cannot interpret the following line:\n".$parser->next_line;
    }
}

1;
