package Ledger::Role::HaveReadableElementsList;
use Moose::Role;
use namespace::sweep;
use MooseX::ClassAttribute;

with ('Ledger::Role::HaveReadableElements');

requires '_setupElementKinds';

class_has '_elementKinds' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    builder  => '_setupAndRegisterElementKinds',
    handles  => {
	_registerElementKind   => 'push',
	_listElementKindsOrig  => 'elements',
	_listElementKinds      => 'elements',
	_elementKindsRegistrationRequired  => 'is_empty',
    },
    init_arg => undef,
    trigger  => \&_elementKinds_set,
    lazy     => 1,
    );

use UNIVERSAL::require;
sub _elementKinds_set {
    my ( $self, $newElementKinds, $oldElementKinds ) = @_;

    #print "Registering by trigger ", join(", ", @{$newElementKinds}), "\n";
    foreach my $kind (@{$newElementKinds}) {
	$kind->require or die $@;
    }
}

sub _setupAndRegisterElementKinds {
    my ($class) = @_;
    my $default = $class->_setupElementKinds(@_);
    #print "Registering from builder ", join(", ", @{$default}), "\n";
    foreach my $kind (@{$default}) {
	$kind->require or die $@;
    }
    return $default;
}

before '_registerElementKind' => sub {
    my $self = shift;
    my @kinds = @_;
    #print "Registering by push ", join(", ", @kinds), "\n";
    for my $kind (@kinds) {
	#print "kind $kind in ",$self->meta->name,"\n";
	$kind->require or die $@;
    }
};

sub BUILD {}

before 'BUILD' => sub {
    my $self = shift;
    if ($self->_elementKindsRegistrationRequired) {
	$self->_registerElementKind(@{$self->_setupAndRegisterElementKinds});
    }
};

1;
