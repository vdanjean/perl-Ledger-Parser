package Ledger::Journal;
use Moose;
use namespace::sweep;

our $DATE = '2016-01-07'; # DATE
our $VERSION = '0.06'; # VERSION

with (
    'Ledger::Role::HaveParsableElementsList',
    'Ledger::Role::HaveJournalElements' => {
	-alias => {
	    _validateElements => 'validate',
	    as_string => '_as_string',
	},
    },
    );

has '+elements' => (
    isa      => 'ArrayRef[Ledger::Journal::Element]',
    );

sub _doElementKindsRegistration {
    my $self = shift;
    #print "registering\n";
    $self->_registerElementKind('Ledger::Journal::Note', 'Ledger::Journal::Blank', 'Ledger::Transaction');
};

sub _parsingEnd {
    return 0;
}

sub as_string {
    my $self = shift;
    $self->validate;
    return $self->_as_string;
}

#sub validate {
#    my $self=shift;
#    $self->_validateElements;
#}

#use Carp;

#sub new {
#    my ($class, %attrs) = @_;

#    if (!$attrs{_parsed}) {
#        $attrs{_parsed} = [];
#    }
#    if (!$attrs{_parser}) {
#        require Ledger::Parser;
#        $attrs{_parser} = Ledger::Parser->new;
#    }

#    bless \%attrs, $class;
#}

#sub empty {
#    my $self = shift;
#    #$self->_discard_cache;
#    $self->{_parsed} = [];
#}

1;
# ABSTRACT: Represent Ledger journal

__END__

=pod

=encoding UTF-8

=head1 NAME

Ledger::Journal - Represent Ledger journal

=head1 VERSION

This document describes version 0.04 of Ledger::Journal (from Perl distribution Ledger-Parser), released on 2015-03-26.

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Ledger-Parser>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Ledger-Parser>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Ledger-Parser>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
