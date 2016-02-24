package Ledger::Role::Iterator::Elements;
use Moose::Role;
use namespace::sweep;
use Ledger::Util::Iterator;

requires '_iterable_elements';

sub _elementIteratorNext {
    my $self = shift;
    my %options = (@_);
    my $subiterator;
    my @curIterableElements=$self->_iterable_elements;
    #print "elemIterNext 1\n";
    my $follow_include=exists($options{'follow-includes'});

    return sub {
	my $next;
      LOOP: while(1) {
	  #print "elemIterNext/sub 1\n";
	  if (defined($subiterator)) {
	      #print "elemIterNext/sub 1\n";
	      $next = $subiterator->next(@_);
	      #print "elemIterNext/sub 2 ($next)\n";
	      return $next if defined($next);
	      #print "elemIterNext/sub 3\n";
	      $subiterator=undef;
	  }
	  $next = shift @curIterableElements;
	  #print "elemIterNext/sub 4\n";
	  return undef if not defined($next);
	  #print "elemIterNext/sub 5 ($next)\n";
	  if ($follow_include
	      && $next->isa('Ledger::Journal::Include')
	      && $next->loaded) {
	      $subiterator=$next->incJournal->getElementsIterator(
		  %options,
		  );;
	      next;
	  }
	  if ($next->does('Ledger::Role::Iterator::Elements')) {
	      #print "elemIterNext/sub 6\n";
	      $subiterator=$next->getElementsIterator(
		  %options,
		  );
	  }
	  return $next;
      }
    };

}

sub getElementsIterator {
    my $self = shift;
    my %options = (@_);
    
    my $iteratorNext = $self->_elementIteratorNext(@_);
    #print "iterator 1\n";
    
    return Ledger::Util::Iterator->new(
	'next_function' => sub {
	    #print "iterator/next_function 1\n";
	    my $next=$iteratorNext->();
	    while (defined($next) && ! $next->isa('Ledger::Element')) {
		#print "iterator/next_function skipped next: $next\n";
		$next=$iteratorNext->();
	    }
	    #print "iterator/next_function 2: $next\n";
	    return $next;
	},
	);
}

1;
