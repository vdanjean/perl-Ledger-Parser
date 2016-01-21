package Ledger::Element;
use Moose;
use namespace::sweep;

with 'Ledger::Role::HaveParent';

sub validate {
    my $self=shift;
    my $options=shift // {};
    print "Validating ".blessed($self)."\n";
    if ($self->does('Ledger::Role::HaveValues')) {
	print "Validating Values in ".blessed($self)."\n";
 	$self->validateValues(@_);
    }
    if ($self->does('Ledger::Role::HaveElements')) {
	print "Validating Elements in ".blessed($self)."\n";
	$self->validateElements(@_);
    }
    return 1;
}

1;

=head1 DESCRIPTION

This object will be the base object for all that represent a (full)line or
continuous group of (full)lines in a Ledger journal.

