package Ledger::Util::Iterator;
use Moose;
use namespace::sweep;

has '_get_next' => (
    is          => 'ro',
    isa         => 'CodeRef',
    init_arg    => 'next_function',
    required    => 1,
    );

has '_next' => (
    is          => 'rw',
    predicate   => '_has_next',
    clearer     => '_unset_next',
    init_arg    => undef,
    );

has '_last' => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 0,
    );

sub has_next {
    my $self = shift;
    return 0 if $self->_last;
    return 1 if $self->_has_next;
    $self->_next($self->_get_next->(@_));
    if (not defined($self->_next)) {
	$self->_last(1);
	return undef;
    }
    return 1;
}

sub next {
    my $self = shift;
    return undef if not $self->has_next(@_);
    my $e = $self->_next;
    $self->_unset_next;
    return $e;
}

1;
