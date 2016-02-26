package Ledger::Role::ApplyRecursive;
use Moose::Role;
use namespace::sweep;
use Carp;

sub applyRecursive {
    my $self = shift;

    $self->cleanRecursive();
    my @tags=( {} );
    my $elem_it = $self->iterator(
	'enter-element-hooks' => [
	    sub {
		shift;
		my $elem = shift;
		if ($elem->does('Ledger::Role::HaveTags')) {
		    unshift @tags, {
			%{$tags[0]},
			$elem->tags,
		    };
		}
	    }
	],
	'exit-element-hooks' => [
	    sub {
		shift;
		my $elem = shift;
		if ($elem->does('Ledger::Role::HaveTags')) {
		    shift @tags;
		}
	    }
	],
	'follow-includes'=>1,
	'select-element' => sub {
	    return shift->does("Ledger::Role::Element::AppliedTags");
	}
	);
    
    while (defined(my $elem = $elem_it->next)) {
	# 1 and not 0 because we do not want to register our own tags as inherited
	$elem->_register_inheritedTags(%{$tags[1]});
    }
}

sub cleanRecursive {
    my $self = shift;
    my $elem_it = $self->iterator(
	'follow-includes'=>1,
	'select-element' => sub {
	    return shift->does("Ledger::Role::Element::AppliedTags");
	}
	);
    
    while (defined(my $elem = $elem_it->next)) {
	$elem->_reset_inheritedTags();
    }
	
    
}
1;
