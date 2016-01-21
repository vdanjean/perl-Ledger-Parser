package Ledger::Exception::ParseError;
use Moose;
use namespace::sweep;

extends 'Ledger::Exception';

has 'line' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    );

has 'parser_prefix' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    );

has 'suggestionTypes' => (
    traits   => ['Array'],
    is       => 'ro',
    # Array of type names that implement Ledger::Role::Readable
    isa      => 'ArrayRef[Str]',
    required => 1,
    default  => sub { [] },
    handles  => {
	all_types   => 'elements',
	_add_type   => 'push',
	_map_types   => 'map',
	_filter_types=> 'grep',
	#find_element   => 'first',
	get_type    => 'get',
	#join_elements  => 'join',
	count_types => 'count',
	#has_options    => 'count',
	has_no_types=> 'is_empty',
	#sorted_options => 'sort',
    },
    );

has 'abortParsing' => (
    is       => 'ro',
    required => 1,
    default  => 0,
    );

1;

