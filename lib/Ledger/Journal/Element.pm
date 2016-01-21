package Ledger::Journal::Element;
use Moose;
use namespace::sweep;

extends 'Ledger::Element';

1;

=head1 DESCRIPTION

This object will be the base object for all Element objects that
can be added into a Ledger::Journal object (more precisely into a object
with the 'Ledger::Role::HaveJournalElements' role)


