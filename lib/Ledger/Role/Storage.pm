package Ledger::Role::Storage;
use Moose::Role;
use namespace::sweep;

has '_storage' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { {} },
    required => 1,
    handles  => {
        var_list            => 'keys',
	var_values          => 'elements',
	var_pairs           => 'kv',
	#has_no_tags         => 'is_empty',
	#has_tags            => 'count',
	var_exists          => 'exists',
	has_var             => 'exists',
	var_get             => 'get',
	var_set             => 'set'
	#all_named_values   => 'elements',
	#all_values         => 'values',
	#_register_value    => 'set',
	#_add_valued_tag     => 'set',
	#_filter_types=> 'grep',
        #find_element   => 'first',
	#get_type    => 'get',
	#join_elements  => 'join',
	#count_types => 'count',
	#has_options    => 'count',
	#has_no_types=> 'is_empty',
	#sorted_options => 'sort',
    },
    init_arg => undef,
    );

sub var {
    my $self=shift;
    my $name=shift;
    if (scalar(@_) == 0) {
	return $self->var_get($name);
    } else {
	return $self->var_set($name, @_);
    }
}

1;
