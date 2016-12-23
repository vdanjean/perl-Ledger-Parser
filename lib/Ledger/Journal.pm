package Ledger::Journal;
use Moose;
use namespace::sweep;

# DATE
# VERSION

with (
    'Ledger::Role::HaveParent',
    'Ledger::Role::HaveReadableElementsList',
    'Ledger::Role::HaveJournalElements' => {
	-alias => {
	    validateElements => 'validate',
	    as_string => '_as_string',
	},
    },
    'Ledger::Role::ApplyRecursive',
    );

has '+elements' => (
    isa      => 'ArrayRef[Ledger::Journal::Element]',
    );

has 'file' => (
    is        => 'ro',
    isa       => 'Path::Class::File',
    predicate => 'is_file',
    );

has 'parseErrors' => (
    traits    => ['Array'],
    is        => 'ro',
    isa       => 'ArrayRef[Ledger::Exception::ParseError]',
    default   => sub { [] },
    lazy      => 1,
    handles  => {
        allParseErrors   => 'elements',
	addParseError    => 'push',
	parsingOK        => 'is_empty',
    },
    );

before 'addParseError' => sub {
    my $self = shift;

    my $die_on_error = $self->config->die_on_first_error//0;
    my $display = $self->config->display_errors//1;

    if ($display) {
	binmode(STDERR, ":utf8");
    }
    foreach my $err (@_) {
	if ($display) {
	    print STDERR $err->parser_prefix, $err->message, "\n";
	}
	if ($die_on_error) {
	    die $err->parser_prefix.$err->message."\n";
	}
    }
};

sub _setupElementKinds {
    return [
	'Ledger::Transaction',
	'Ledger::Journal::Blank',
	'Ledger::Journal::Note',
	'Ledger::Journal::Include',
	'Ledger::Journal::ApplyTag',
	'Ledger::Account',
	'Ledger::Journal::Tag',
	'Ledger::Journal::Commodity',
	'Ledger::Journal::Bucket',
	'Ledger::Journal::Python',
	];
}

sub _readEnded {
    my $self = shift;
    my $reader = shift;
    my $line = $reader->next_line;

    return ! defined($line);
}

sub as_string {
    my $self = shift;
    #print "Before validate\n";
    $self->validate;
    #print "After validate\n";
    return $self->_as_string;
}

sub _value_updated {
    my $self = shift;
    # TODO: mark journal as dirty
    # ... and cleanup in as_string ?
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
