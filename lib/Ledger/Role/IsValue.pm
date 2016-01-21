package Ledger::Role::IsValue;
use Moose::Role;
use namespace::sweep;

with (
    'Ledger::Role::HaveParent',
    'Ledger::Role::HaveCachedText',
    );

#requires 'value';

has 'value' => (
    is       => 'rw',
    isa      => 'Ledger::Internal::Error', # must be specialized
    trigger  => sub {
	my $self=shift;
	$self->_clear_cached_text(@_);
    },
    predicate=> 'present',
    clearer  => 'reset',
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

after '_clear_cached_text' => sub {
    my $self=shift;
    #print "In after _clear_cached_text in ", blessed($self), ' with parent ',
    #blessed($self->parent), "\n";
    $self->parent->_clear_cached_text;
};

sub validate {
    my $self = shift;
    print "Validating ".blessed($self)." for attr ".$self->name.
	": ".$self->present."/".$self->required."\n";
    if ( $self->required && ! $self->present) {
	die "Missing required value '".$self->name."' in\n".$self->parent->as_string."\n";
    }
}

1;
