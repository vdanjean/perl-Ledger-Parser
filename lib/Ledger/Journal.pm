package Ledger::Journal;
use Moose;
use namespace::sweep;

# DATE
# VERSION

with (
    'Ledger::Role::HaveReadableElementsList',
    'Ledger::Role::HaveJournalElements' => {
	-alias => {
	    validateElements => 'validate',
	    as_string => '_as_string',
	},
    },
    );

has '+elements' => (
    isa      => 'ArrayRef[Ledger::Journal::Element]',
    );

has 'config' => (
    is         => 'rw',
    does       => 'Ledger::Role::Config',
    required   => 1,
    );

sub _setupElementKinds {
    return [
	'Ledger::Transaction',
	'Ledger::Journal::Blank',
	'Ledger::Journal::Note',
	'Ledger::Account',
	'Ledger::Journal::Tag',
	'Ledger::Journal::Commodity',
	];
}

sub _readEnded {
    return 0;
}

sub as_string {
    my $self = shift;
    $self->validate;
    return $self->_as_string;
}

sub journal {
    my $self = shift;
    return $self;
}

sub numlines {
    return 0;
}

sub startlinenum {
    return 0;
}

1;
# ABSTRACT: Represent Ledger journal

=head1 SYNOPSIS

Obtain a journal object C<$journal> from parsing a Ledger file/string using
L<Ledger::Parser>'s C<read_file> or C<read_string> method. Or, to produce an
empty journal:

 $journal = Ledger::Journal->new;

Empty journal:

 $journal->empty;

Dump journal into Ledger string:

 print $journal->as_string;

 # or just:
 print $journal;



=head1 ATTRIBUTES


=head1 METHODS

=head2 new(%attrs) => obj

=head2 $journal->as_string => str

Return journal object rendered as string. Automatically used for
stringification.


=head2 $journal->empty()

Empty journal.


=head1 SEE ALSO

L<Ledger::Parser>
