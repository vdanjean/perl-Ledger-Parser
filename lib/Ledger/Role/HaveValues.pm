package Ledger::Role::HaveValues;
use Moose::Role;
use MooseX::ClassAttribute;
use Ledger::Role::IsValue;

has 'values' => (
    traits    => ['Hash'],    
    is        => 'ro',
    isa       => 'HashRef[Ledger::Role::IsValue]',
    required => 1,
    default  => sub { {} },
    handles  => {
	all_named_values       => 'elements',
	all_values       => 'values',
	_register_value  => 'set',
	#_filter_types=> 'grep',
	#find_element   => 'first',
	#get_type    => 'get',
	#join_elements  => 'join',
	#count_types => 'count',
	#has_options    => 'count',
	#has_no_types=> 'is_empty',
	#sorted_options => 'sort',
    },
    );

class_has 'value_names' => (
    traits    => ['Array'],    
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    default  => sub { [] },
    handles  => {
	all_value_names       => 'elements',
	_register_value_name  => 'push',
	#_map_types       => 'map',
	#_filter_types=> 'grep',
	#find_element   => 'first',
	#get_type    => 'get',
	#join_elements  => 'join',
	#count_types => 'count',
	#has_options    => 'count',
	#has_no_types=> 'is_empty',
	#sorted_options => 'sort',
    },
    );

before 'cleanup' => sub {
    my $self = shift;
    map { $_->cleanup(@_); } $self->all_values;
};

1;
