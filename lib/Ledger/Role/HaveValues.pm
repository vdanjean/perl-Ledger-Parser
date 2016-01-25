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
    lazy      => 1,
    );

class_has 'value_names' => (
    traits    => ['Array'],
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    default  => sub {
	my $self = shift;
	return _get_all_value_names($self);
    },
    handles  => {
	all_value_names       => 'elements',
	#_register_value_name  => 'push',
	#_map_types       => 'map',
	#_filter_types=> 'grep',
	#find_element   => 'first',
	#get_type    => 'get',
	#join_elements  => 'join',
	#count_types => 'count',
	#has_options    => 'count',
	#_has_no_value_names => 'is_empty',
	#sorted_options => 'sort',
    },
    lazy => 1,
    );


# return an ARRAYREF
sub _get_all_value_names {
    my $class = shift;
    my $info = shift // "constructor";
    my $meta = $class;
    my $value_names=[];

    if (not $class->isa('Moose::Meta::Class')) {
	$meta=$class->meta;
    }

    #print "Attributes ($info) in ".$meta->name." / $meta\n";
    for my $attr ( $meta->get_all_attributes ) {
	my $v = $attr->type_constraint->is_a_type_of("Ledger::Value");
	#print "  + ",$attr->name, " ($v)\n";
	if ($v) {
	    push @$value_names, $attr->name;
	}
    }
    return $value_names;
}

# return a sorted ARRAY
sub get_all_value_names {
    my $self = shift;
    my $names = $self->_get_all_value_names;

    return sort {
	my $raw_a='_'.$a.'_rawvalue';
	my $raw_b='_'.$b.'_rawvalue';
	$self->$raw_a->order <=> $self->$raw_b->order
    } @{$names};
}

before 'cleanup' => sub {
    my $self = shift;
    map { $_->cleanup(@_); } $self->all_values;
};

sub validateValues {
    my $self=shift;
    my @res = map {
	my $meth=$_.'_validate';
	$self->$meth(@_);
    } $self->all_value_names;
}

sub formatValueParams {
    my $self=shift;

    return map {
	my $name=$_;
	my $_name_rawvalue='_'.$name.'_rawvalue';
	my $type = $self->$_name_rawvalue->format_type;
	my %params=();
	if ($type eq 'string') {
	    $params{'value'} = $self->$_name_rawvalue->value_str;
	} elsif ($type eq 'skip') {
	    return;
	} elsif ($type eq 'Num') {
	} else {
	    print "**** unknown format type $type for $name\n";
	}
	Ledger::Util->buildFormatParam(
	    $name,
	    'object' => $self,
	    'type' => $self->$_name_rawvalue->format_type,
	    %params,
	    );
    } $self->all_value_names;
}

sub compute_text_from_values {
    my $self = shift;
    my $format = shift;
    my @formatParams=();

    push @formatParams, $self->formatValueParams();

    my $str=Ledger::Util->format(
	$format => {@formatParams}
	);
    if ($str->[0] != 200) {
	$self->_err($str->[1]);
    }
    $str->[1] =~ s/\h+(\R?)\z/$1/m;
    return $str->[1];
}

1;
