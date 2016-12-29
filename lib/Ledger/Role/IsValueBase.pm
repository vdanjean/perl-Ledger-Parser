package Ledger::Role::IsValueBase;
use Moose::Role;
use namespace::sweep;
use Ledger::Exception::Validation;
use Ledger::Util::Filter ':constants';

with (
    'Ledger::Role::IsParent',
    'Ledger::Role::HaveParent',
    'Ledger::Role::IsPrintable',
    'Ledger::Role::ParseValue',
    );

requires (
    'as_string',
    'value_str'
    );

has 'value' => (
    is       => 'rw',
    isa      => 'Ledger::Internal::Error', # must be specialized
    trigger  => sub {
	my $self=shift;
	$self->_value_updated(@_);
    },
    predicate=> 'present',
    clearer  => '_reset',
    );

has 'name' => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    );

has 'required' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
    default  => 0,
    lazy     => 1,
    );

has 'default_value' => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_default_value',
    writer    => '_set_default_value',
    );

has 'reset_on_cleanup' => (
    is         => 'ro',
    isa        => 'Bool',
    required   => 1,
    default    => 0,
    lazy       => 1,
    );

has 'format_type' => (
    is        => 'ro',
    required  => 1,
    lazy      => 1,
    default   => 'string',
    );

has 'order' => (
    is        => 'ro',
    isa       => 'Num',
    required  => 1,
    default   => 0,
    );

sub BUILD {
    my $self = shift;
    my $args = shift;

    #print "BUILD for value ",$self->name,"\n";
    if (exists($args->{'_default_code'})) {
	my $val=$args->{'_default_code'}->($self);
	#print "VAL=$val\n";
	$self->_set_default_value($val);
	$self->value($val);
    }
};

sub reset {
    my $self = shift;

    if ($self->has_default_value) {
	$self->value_str($self->default_value);
    } else {
	$self->_reset(@_);
    }
}

sub validate {
    my $self = shift;
#    print "Validating ".blessed($self)." for attr ".$self->name.
#	": ".$self->present."/".$self->required."\n";
    if ( $self->required && ! $self->present) {
	die
	    [
	     Ledger::Exception::Validation->new(
		 'message' => "Missing required value '".$self->name,
		 'fromElement' => $self->element,
	     ),
	    ];
    }
}

sub compute_text {
    my $self = shift;
    
    return '' if ! $self->present;
    return $self->_compute_text;
}

sub _compute_text {
    my $self = shift;
    
    return "".$self->value;
}

before 'cleanup' => sub {
    my $self = shift;
    if ($self->reset_on_cleanup) {
	$self->reset;
    }
};

## BEGIN Hash support
use Data::Dumper;
sub _hasSpecificValue {
    my $self = shift;
    if (not $self->has_default_value) {
	return 1;
    }
    my $def = $self->default_value;
    my $v=$self->value;
    #print Dumper($v), "\n";
    if (ref($self->value)) {
	return $self->value != $self->default_value;
    } else {
	return $self->value ne $self->default_value;
    }
}

sub _filterValue {
    my $self = shift;
    my $name = shift;
    my $hval = shift;
    my %opts = (@_);

    if ($opts{'filter-absent'} // 1) {
	if (not defined($hval)) {
	    #print STDERR "filtering absent $name\n";
	    return FILTER;
	}
    }
    if ($opts{'filter-generic'} // 1) {
	if (not $self->_hasSpecificValue) {
	    #print STDERR "filtering generic $name\n";
	    return FILTER;
	}
    }
    if ($opts{'filter-spaces'} // 1) {
	if ($name =~ /^ws[0-9]+$/) {
	    #print STDERR "filtering space $name\n";
	    return FILTER;
	}
    }
    if ($opts{'filter-empty'} // 1) {
	if (ref($hval) eq 'HASH') {
	    if (!%{$hval}) {
		#print STDERR "filtering empty hash $name\n";
		return FILTER;
	    }
	} elsif (ref($hval) eq "") {
	    if ("" eq $hval) {
		#print STDERR "filtering empty string $name\n";
		return FILTER;
	    }
	}
    }
    return ACCEPT;
}

sub _hashKey {
    my $self = shift;
    return $self->name;
}

sub _hashValue {
    my $self = shift;
    return $self->value_str;
}

sub toHash {
    my $self = shift;

    my $hkey=$self->_hashKey;
    my $val=$self->_hashValue;
    #print Dumper(\@_);
    my $filter=$self->_filterValue($hkey, $val, @_) // ACCEPT;
    if ($filter == FILTER) {
	return ();
    }
    return (
	$self->_hashKey => $val
	);
}
## END Hash support

1;
