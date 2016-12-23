package Ledger::Role::HaveElements;
use Moose::Role;
use namespace::sweep;
use List::Util qw(sum);
use Ledger::Element;

with (
    'Ledger::Role::IsParent',
    'Ledger::Role::IsPrintable',
    'Ledger::Role::Iterator::Elements' => {
	-alias  => { 
	    'getElementsIterator' => 'iterator',
	    'getValuesElementsIterator' => 'valuesIterator',
	},
    },
    );

requires 'numlines';

has 'elements' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Ledger::Role::HaveParent]',
    default  => sub { [] },
    required => 1,
    handles  => {
	all_elements   => 'elements',
	_iterable_elements   => 'elements',
	_add_element   => 'push',
	_map_elements   => 'map',
	_filter_elements=> 'grep',
	#find_element   => 'first',
	get_element    => 'get',
	#join_elements  => 'join',
	count_elements => 'count',
	#has_options    => 'count',
	has_no_elements=> 'is_empty',
	#sorted_options => 'sort',
	empty          => 'is_empty',
    },
    init_arg => undef,
    );

sub _iterable_elements {
    my $self = shift;
    return $self->_printable_elements(@_);
}

sub _printable_elements {
    my $self = shift;
    return $self->all_elements(@_);
}

sub as_string {
    my $self = shift;
    #print "Printing ", ref($self), "\n";
    return join("", map { $_->as_string(); } $self->_printable_elements(@_));
}

before 'cleanup' => sub {
    my $self = shift;
    $self->_map_elements( sub { $_->cleanup(@_); } );
};

sub validateElements {
    my $self=shift;
    my @res = $self->_map_elements(sub { $_->validate(@_); })
}

around 'numlines' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig() 
	+ sum($self->_map_elements(sub { $_->numlines(@_); }));
};

1;

