package Ledger::Role::HaveValues;
use Moose::Role;
use namespace::sweep;
use MooseX::ClassAttribute;
use Ledger::Role::IsValue;
use TryCatch;
use Ledger::Util qw(indent);

with(
    'Ledger::Role::IsParent',
    );

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

sub load_from_reader_helper {
    my $self = shift;
    my %options = ( @_ );
    my $reader = $options{'reader'} // die "Missing reader parameter";

    my $line = $reader->pop_line;
    #print "reading values of ".$self->meta->name." from $line";
    my $accept_re;
    if (defined($options{'accept_re'})) {
	$accept_re = $options{'accept_re'};
    } elsif (defined($options{'accept_line_re'})) {
	$accept_re = $options{'accept_line_re'};
	$accept_re = qr/$accept_re(?:\R?)\z/;
    } elsif (defined($options{'accept_with_blank_re'})) {
	$accept_re = $options{'accept_with_blank_re'};
	$accept_re = qr/$accept_re(?:\s|(?:\R?\z))/;
    }
    if(defined($accept_re)) {
	if ($line !~ /$accept_re/) {
	    # soft error, we give back the line
	    $reader->give_back_next_line($line);
	    die Ledger::Exception::ParseError->new(
		'line' => $line,
		'parser_prefix' => $reader->error_prefix,
		'message' => (
		    $options{'noaccept_error_msg'}
		    // ("not a ".$self->meta->name." line")),
		);
	}
    }
    my $parse_re;
    if (defined($options{'parse_re'})) {
	$parse_re = $options{'parse_re'};
    } elsif (defined($options{'parse_line_re'})) {
	$parse_re = $options{'parse_line_re'};
	$parse_re = qr/$parse_re\s*(?<NL>\R?)\z/;
    }
    my @error_msgs=();
    if ($line =~ /$parse_re/) {
	my %res=(%+);
	if (defined($options{'store'})) {
	    my $vnames;
	    if (ref(\$options{'store'}) eq "SCALAR" ) {
		if ($options{'store'} eq "all") {
		    $vnames = $self->_get_all_value_names;
		} else {
		    die "Invalid value for parameter 'store'";
		}
	    } elsif (ref($options{'store'}) eq "ARRAY" ) {
		$vnames=$options{'store'};
	    } else {
		die "Invalid parameter 'store'";
	    }
	    my $e;
	    foreach my $opt (@{$vnames}) {
		try {
		    my $opt_str=$opt.'_str';
		    $self->$opt_str($res{$opt}) if defined($res{$opt});
		} catch (Ledger::Exception::ValueParseError $e) {
		    push @error_msgs, $opt, $e->message;
		}
	    }
	}
	# after as any call to XXX_str(...) reset the cached text
	if ($options{'cache_line'} // 1) {
	    $self->_cached_text($line);
	}

	if (scalar(@error_msgs) == 0) {
	    return \%res;
	}
    }
    # A parsing error occurs
    my %attr=(
	'line' => $line,
	'parser_prefix' => $reader->error_prefix,
	);
    my $msg;
    if (scalar(@error_msgs)) {
	# we accepted the line (possibly twice), it is an hard error
	$attr{'abortParsing'} = 1;
	$msg = (
	    $options{'parse_value_error_msg'}
	    // ("in ".$self->meta->name.
		" while parsing the following value(s):"))."\n";
	my %errs = ( @error_msgs );
	my @vname=keys(%errs);
	$msg .= join("\n", (
			 map {
			     "{".$_."}: ".indent('  ', $errs{$_});
			 } @vname
		     ));
    } elsif(defined($accept_re)) {
	# we accepted the line, it is an hard error
	$attr{'abortParsing'} = 1;
	$msg = (
	    $options{'accept_error_msg'}
	    // ("invalid line (but recognised as a ".
		$self->meta->name.")"));
    } else {
	# it can be a soft error (not the good parser called)
	$reader->give_back_next_line($line);
	$msg = (
	    $options{'noaccept_error_msg'}
	    // ("invalid ".$self->meta->name." line"));
    }
    die Ledger::Exception::ParseError->new(%attr, 'message' => $msg);
}

1;
