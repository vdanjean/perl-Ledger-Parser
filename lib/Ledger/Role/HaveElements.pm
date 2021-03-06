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

## BEGIN Hash support
sub _toHashElements {
    my $self = shift;

    my @elements=map {
	my $e=$_;
	my %hr=$e->toHash(@_);
	$hr{'type'}= ref($e);
	$hr{'type'} =~ s/^Ledger:://;
	\%hr
    } $self->all_elements;
    return (
	'elements' => \@elements,
    );
}

around 'toHash' => sub {
    my $orig = shift;
    my $self = shift;

    my %hv = (
	$self->$orig(@_),
	$self->_toHashElements(@_),
	);
    return %hv;
};

requires 'load_values_from_hash';
after 'load_values_from_hash' => sub {
    my $self = shift;
    my $h = shift;

    #print "Loading elements into ", $self->element->meta->name, "\n";

    return if not exists($h->{'elements'});

    for my $he (@{$h->{'elements'}}) {
	$self->add($he->{'type'}, $he);
    }
    #print "Loaded elements into ", $self->element->meta->name, "\n";
};

use Data::Dumper;
use Ledger::Value::Date;
sub _add {
    my $self=shift;
    my $realtype = shift;
    my $contents = shift;
    #delete $contents->{'elements'};
    #print "iHASH=", Dumper($contents), "\n";
    my $element=$realtype->new(
	'parent' => $self,
	'contents' => $contents,
	);
    #"".$transaction;
    #print "VNAME=", join(' ', $transaction->all_value_names), "\n";
    $self->_add_element($element);
    return $element;
}

sub add {
    my $self=shift;
    my $type = shift;
    my $realtype = "Ledger::".$type;

    return $self->_add($realtype, @_)
}

sub copy {
    my $self=shift;
    my $e = shift;
    my $realtype = ref($e);
    my $contents = { $e->toHash };
    
    return $self->_add($realtype, $contents);
}
## END Hash support

1;

