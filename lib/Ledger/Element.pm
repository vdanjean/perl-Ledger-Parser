package Ledger::Element;
use Moose;
use namespace::sweep;

with 'Ledger::Role::HaveParent';

sub validate {
    my $self=shift;
    my $options=shift // {};
    #print "Validating ".blessed($self)."\n";
    if ($self->does('Ledger::Role::HaveValues')) {
	#print "Validating Values in ".blessed($self)."\n";
 	$self->validateValues(@_);
    }
    if ($self->does('Ledger::Role::HaveElements')) {
	#print "Validating Elements in ".blessed($self)."\n";
	$self->validateElements(@_);
    }
    return 1;
}

sub numlines {
    return 1;
}

sub startlinenum {
    my $self = shift;

    my $numline=$self->parent->startnumline;
    $numline+=1 if $self->parent->isa('Ledger::Element');

    for my $e ($self->parent->all_elements) {
	return $numline if $e == $self;
	$numline+=$e->numlines;
    }
    die "$self not in its parent!"
}

1;

=head1 DESCRIPTION

This object will be the base object for all that represent a (full)line or
continuous group of (full)lines in a Ledger journal.

=head1 METHODS

=head2 $object->validate(%params)

call recursively the validate method on all 'Ledger::Value' and
'Ledger::Element' objects.

=head2 $object->numlines()

return the number of lines required to print this element

=head2 $object->startlinenum()

return the number of first line of this element in the Ledger::Journal that own
this object

=cut

package Ledger::Journal::Element;
use Moose;
use namespace::sweep;

extends 'Ledger::Element';

1;

=head1 DESCRIPTION

This object will be the base object for all Element objects that
can be added into a Ledger::Journal object (more precisely into a object
with the 'Ledger::Role::HaveJournalElements' role)

=cut

package Ledger::Transaction::Element;
use Moose;
use namespace::sweep;

extends 'Ledger::Element';

1;

=head1 DESCRIPTION

This object will be the base object for all Element objects that
can be added into a Ledger::Transaction object

=cut

package Ledger::Posting::Element;
use Moose;
use namespace::sweep;

extends 'Ledger::Element';

1;

=head1 DESCRIPTION

This object will be the base object for all Element objects that
can be added into a Ledger::Posting object

=cut

package Ledger::Account::Element;
use Moose;
use namespace::sweep;

extends 'Ledger::Element';

1;

=head1 DESCRIPTION

This object will be the base object for all Element objects that
can be added into a Ledger::Account object

=cut

package Ledger::Journal::Tag::Element;
use Moose;
use namespace::sweep;

extends 'Ledger::Element';

1;

=head1 DESCRIPTION

This object will be the base object for all Element objects that
can be added into a Ledger::Journal::Tag object

=cut

