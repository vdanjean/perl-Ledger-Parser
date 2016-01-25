package Ledger::Role::HaveParent;
use Moose::Role;
use Ledger::Role::IsParent;

has 'parent' => (
    is        => 'ro',
    isa       => 'Ledger::Role::IsParent',
    required  => 1,
    weak_ref  => 1,
    );

sub journal {
    my $self = shift;
    return $self->parent->journal;
}

sub journals {
    my $self = shift;
    return $self->parent->journals;
}

sub config {
    my $self = shift;
    return $self->journals->config;
}

sub _value_updated {
    my $self=shift;

    #print "*** In after _clear_cached_text in ", blessed($self), ' with parent ',
    #blessed($self->parent), "\n";
    #print join(', ', @_), "\n";
    #if ( @_ > 2 ) {
    #	# if this is the first setting time, no need to invalidate the cache
    #	# as it is empty

    if ($self->does('Ledger::Role::HaveCachedText')) {
	if ($self->_text_cached) {
	    $self->_clear_cached_text;
	    $self->parent->_value_updated;
	}
    } else {
	$self->parent->_value_updated;
    }
}

1;

