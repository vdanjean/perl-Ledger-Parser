package Ledger::Role::Element::Layout::WithClosingElement;
use Moose::Role;
use namespace::sweep;

with (
    'Ledger::Role::Element::Layout::WithSubElements',
    'Ledger::Role::HaveElements' => {
	-alias => { 
	    as_string => '_as_string_elements',
	},
	-excludes => [ 'as_string', '_printable_elements' ],
    },
    'Ledger::Role::HaveReadableElementsFromParent',
    );

sub _listElementKindsAppend {
    my $self = shift;
    return (
	$self->meta->name.'::EndLine',
	);
}

sub _printable_elements {
    my $self = shift;
    my $endname=$self->meta->name.'::EndLine';

    use sort 'stable';
    return sort {
	$a->isa($endname) <=> $b->isa($endname)
    } ($self->all_elements(@_));
}

sub _readEnded {
    my $self = shift;
    my $reader = shift;

    if (scalar($self->_filter_elements(sub {
	$_->isa($self->meta->name.'::EndLine')
				       }))) {
	return 1;
    }
	
    my $line = $reader->next_line;
    return (!defined($line));
}

1;
