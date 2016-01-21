package Ledger::Role::IsValue;
use Moose::Role;
use namespace::sweep;

with (
    'Ledger::Role::HaveParent',
    'Ledger::Role::HaveCachedText',
    );

#requires 'value';

has 'raw_value' => (
    is       => 'rw',
    isa      => 'Ledger::Internal::Error', # must be specialized
    trigger  => sub {
	my $self=shift;
	$self->_clear_cached_text(@_);
    },
    predicate=> 'present',
    clearer  => 'reset',
    );

sub value {
    my $self = shift;

    return $self->raw_value(@_) if @_;
    return undef if ! $self->present;
    #print "Getting as string for ".blessed($self)."\n";
    return $self->as_string;
}

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

1;
