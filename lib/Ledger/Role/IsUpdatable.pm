package Ledger::Role::IsUpdatable;
use Moose::Role;
use namespace::sweep;
use Carp;
use Ledger::Util;

my $update_version=0;

has '_update_hooks' => (
    traits    =>  ['Hash'],
    is        => 'ro',
    isa       => 'HashRef[CodeRef|Str]',
    required => 1,
    default  => sub { {} },
    handles  => {
	_update_hooks_list  => 'values',
        #all_named_values   => 'elements',
        #all_values         => 'values',
        #_register_value    => 'set',
	register_update_hook => 'set',
        #_filter_types=> 'grep',
        #find_element   => 'first',
        #get_type    => 'get',
        #join_elements  => 'join',
        #count_types => 'count',
        #has_options    => 'count',
        #has_no_types=> 'is_empty',
        #sorted_options => 'sort',
    },
    lazy      => 1,
    );

has '_in_update' => (
    isa           => 'Bool',
    is            => 'rw',
    default       => 0,
    required      => 1,
    lazy          => 1,
    );

sub updated {
    my $self = shift;
    my %options = @_;

    if (! exists($options{'update-version'})) {
	$options{'update-version'} = ++$update_version;
    }
    
    if ($self->_in_update) {
	if ($self->_in_update == 2) {
	    carp $self->meta->name.": updated recursively called by parent";
	} else {
	    carp $self->meta->name.": updated recursively called by hooks";
	}
	return ;
    }

    $self->_in_update(1);
    my @new_options;
    foreach my $hook ($self->_update_hooks_list) {
	push @new_options, Ledger::Util::run($hook, $self, %options);
    }

    $self->_in_update(2);
    if ($self->does('Ledger::Role::HaveParent')) {
	my $parent=$self->parent;
	if (defined($parent) && $parent->does('Ledger::Role::IsUpdatable')) {
	    $parent->updated(%options, @new_options, 'child' => $self);
	}
    }

    $self->_in_update(0);
}

sub register_update_hooks {}

before 'BUILD' => sub {
    my $self = shift;
    $self->register_update_hooks;
};

1;
