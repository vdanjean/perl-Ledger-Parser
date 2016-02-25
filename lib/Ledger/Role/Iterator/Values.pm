package Ledger::Role::Iterator::Values;
use Moose::Role;
use namespace::sweep;
use Ledger::Util::Iterator;
use Carp;

requires '_iterable_values';

sub getValuesIterator {
    my $self = shift;
    my %global_options = (@_);
    
    my $subiterator;
    my @curIterableValues=$self->_iterable_values;

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
		  $options{'skip-sub-values'}=0;
	      }
	      if (($options{'skip-sub-values'} // 0)) {
		  return undef;
	      }
	      return undef if scalar(@curIterableValues) == 0;
	      $next = shift @curIterableValues;
	      # some values can be undefined
	      next if not defined($next);
	      if (! $next->isa('Ledger::Value')) {
		  carp "$next is not a Ledger::Value!";
		  next;
	      }
	      if (($options{'filter-out-value'} // 0) && $options{'filter-out-value'}->($next)) {
		  next;
	      }
	      if ($next->does('Ledger::Role::Iterator::Values')) {
		  $subiterator=$next->getValuesIterator(
		      %options,
		      );
	      }
	      if (($options{'select-value'} // 0) && !$options{'select-value'}->($next)) {
		  next;
	      }
	      return $next;
	  }
	}
	);
}

1;
