package Ledger::Role::IsValueBase;
use Moose::Role;
use namespace::sweep;
use Ledger::Exception::Validation;

with (
    'Ledger::Role::HaveParent',
    'Ledger::Role::IsPrintable',
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
    );

has 'default_value' => (
    is        => 'ro',
    predicate => 'has_default_value',
    );

has 'format_type' => (
    is        => 'ro',
    required  => 1,
    lazy      => 1,
    default   => 'string',
    );

sub reset {
    my $self = shift;

    if ($self->has_default_value && $self->required) {
	$self->value($self->default_value);
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

1;
