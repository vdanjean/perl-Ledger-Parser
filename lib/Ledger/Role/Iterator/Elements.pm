package Ledger::Role::Iterator::Elements;
use Moose::Role;
use namespace::sweep;
use Ledger::Util::Iterator;
use Ledger::Util;
use Carp;

requires '_iterable_elements';

sub getElementsIterator {
    my $self = shift;
    my %global_options = (@_);
    
    my $subiterator;
    my $cur_element;
    my @curIterableElements=$self->_iterable_elements;

    if ($global_options{'add-self'} && $self->isa('Ledger::Element')) {
	unshift @curIterableElements, $self;
	delete($global_options{'add-self'});
    }
    #my $follow_include=exists($options{'follow-includes'});

    
    return Ledger::Util::Iterator->new(
	'next_function' => sub {
	    my %local_options=(@_);
	    my %options=(%global_options, %local_options);
	    my $next;

	  LOOP: while(1) {
	      if (defined($subiterator)) {
		  $next = $subiterator->next(%local_options);
		  return $next if defined($next);
		  $subiterator=undef;
		  $options{'skip-sub-elements'}=0;
		  if ( defined($options{'exit-element-hooks'})) {
		      Ledger::Util::runs($options{'exit-element-hooks'}, undef, $cur_element);
		  }
		  $cur_element=undef;
	      }
	      if (($options{'skip-sub-elements'} // 0)) {
		  return undef;
	      }
	      $next = shift @curIterableElements;
	      return undef if not defined($next);
	      if (! $next->isa('Ledger::Element')) {
		  carp "$next is not a Ledger::Element!";
		  next;
	      }
	      if (($options{'follow-includes'} // 0)
		  && $next->isa('Ledger::Journal::Include')
		  && $next->loaded) {
		  $cur_element=$next;
		  if ( defined($options{'enter-element-hooks'})) {
		      Ledger::Util::runs($options{'enter-element-hooks'}, undef, $cur_element);
		  }
		  $subiterator=$next->incJournal->getElementsIterator(
		      %options,
		      );;
		  next;
	      }
	      my $filter=0;
	      # 0: keep element
	      # 1: skip it totally
	      # 2: skip its subelements
	      if (exists($options{'filter-out-element'})) {
		  $filter=$options{'filter-out-element'}->($next);
	      }
	      if ($filter && $filter != 2) {
		  next;
	      }
	      if ($filter != 2
		  && $next->does('Ledger::Role::HaveElements')) {
		  $cur_element=$next;
		  if ( (!defined($options{'enter-element'})) || $options{'enter-element'}->($cur_element)) {
		      if ( defined($options{'enter-element-hooks'})) {
			  Ledger::Util::runs($options{'enter-element-hooks'}, undef, $cur_element);
		      }
		      $subiterator=$next->getElementsIterator(
			  %options,
			  );
		  }
	      }
	      if (($options{'select-element'} // 0) && !$options{'select-element'}->($next)) {
		  next;
	      }
	      
	      return $next;
	  }
	}
	);
}

sub getValuesElementsIterator {
    my $self=shift;
    my %global_options = (@_);
    my $element_it=$self->getElementsIterator(
	'add-self' => 1,
	%global_options,
	);
    my $value_it=undef;
    
    return Ledger::Util::Iterator->new(
	'next_function' => sub {
	    my %local_options=(@_);
	    
	  LOOP: while(1) {
	      if (!defined($value_it)) {
		  my $e=$element_it->next;
		  return undef if not defined($e);
		  if (!$e->does("Ledger::Role::Iterator::Values")) {
		      next;
		  }
		  $value_it=$e->getValuesIterator(%global_options);
	      }
	      my $next=$value_it->next;
	      return $next if defined($next);
	      $value_it=undef;
	  }
	},
	);
}

1;
