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
    #print "has_next 1\n";
    return 0 if $self->_last;
    #print "has_next 2\n";
    return 1 if $self->_has_next;
    my $c=$self->_get_next;
    #print "has_next 3 $c\n";
    $self->_next($self->_get_next->());
    #print "has_next 4\n";
    if (not defined($self->_next)) {
	#print "has_next 5\n";
	$self->_last(1);
	#print "has_next 6\n";
	return undef;
    }
    #print "has_next 7\n";
    return 1;
}

sub next {
    my $self = shift;
    #print "next 1\n";
    return undef if not $self->has_next;
    #print "next 2\n";
    my $e = $self->_next;
    #print "next 3\n";
    $self->_unset_next;
    #print "next 4 ($e)\n";
    return $e;
}

1;
