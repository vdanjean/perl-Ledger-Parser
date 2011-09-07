package Ledger::Parser;

use 5.010;
use Moo;

use File::Slurp;
use Ledger::Journal;
use Scalar::Util qw(blessed);

# VERSION

sub parse {
    my ($self, $arg) = @_;
    die "Please specify a defined argument to parse()\n" unless defined($arg);

    my $aryref;
    my $r = ref($arg);
    if (!$r) {
        $aryref = [split /^/, $arg];
    } elsif ($r eq 'ARRAY') {
        $aryref = $arg;
    } elsif ($r eq 'GLOB' || blessed($arg) && $arg->isa('IO::Handle')) {
        $aryref = [<$arg>];
    } elsif ($r eq 'CODE') {
        my @chunks;
        while (defined(my $chunk = $arg->())) {
            push @chunks, $chunk;
        }
        $aryref = \@chunks;
    } else {
        die "Invalid argument, please supply a ".
            "string|arrayref|coderef|filehandle\n";
    }
    Ledger::Journal->new(raw_lines=>$aryref);
}

sub parse_file {
    my ($self, $filename) = @_;
    $self->parse([read_file($filename)]);
}

1;
# ABSTRACT: Parse Ledger journals
__END__

=head1 SYNOPSIS

 use 5.010;
 use Ledger::Parser;
 my $ledgerp = Ledger::Parser->new();

 # parse a file
 my $journal = $ledgerp->parse_file("$ENV{HOME}/money.dat");

 # parse a string
 $journal = $ledgerp->parse(<<EOF);
 ; -*- Mode: ledger -*-
 09/06 dinner
 Expenses:Food          $10.00
 Expenses:Tips        20000.00 IDR
 Assets:Cash:Wallet

 2011/09/07 opening balances
 Assets:Mutual Funds:Mandiri  10,305.1234 MFEQUITY_MANDIRI_IAS
 Equity:Opening Balances

 P 2011/08/01 MFEQUITY_MANDIRI_IAS 1,453.8500 IDR
 P 2011/08/31 MFEQUITY_MANDIRI_IAS 1,514.1800 IDR
 EOF

 # get the transactions
 my @tx = $journal->get_transactions;

 # get the postings of a transaction
 my @postings = $tx[0]->get_postings;

 # get all the mentioned accounts
 my @accts = $journal->get_accounts;


=head1 DESCRIPTION

This module parses Ledger journal into Perl document object. See
http://ledger-cli.org/ for more on Ledger, the command-line double-entry
accounting system software.

This module uses L<Log::Any> logging framework.

This module uses L<Moo> object system.


=head1 ATTRIBUTES


=head1 METHODS

=head2 new()

Create a new parser instance.

=head2 $ledgerp->parse($str | $arrayref | $coderef | $filehandle) => $journal

Parse ledger journal (which can be contained in a $str, an array of lines
$arrayref, a subroutine which will be called for chunks until it returns undef,
or a filehandle).

Will die if there are parsing errors in journal.

Returns L<Ledger::Journal> object. The object will contain a series of
L<Ledger::Transaction> objects, which themselves will be comprised of a series
of L<Ledger::Posting> objects.

=head2 $orgp->parse_file($filename) => $journal

Just like parse(), but will load document from file instead.


=head1 FAQ

=head2 Why? Ledger is already a command-line program. It even has 'lisp' output.

I am not trying to reimplement/port Ledger to Perl. This module doesn't do
reporting or parse expressions or many other Ledger features. I use this module
mainly to insert/delete/edit transactions to journal file, e.g. for
programatically reconciling journal with internet banking statement.

=cut
