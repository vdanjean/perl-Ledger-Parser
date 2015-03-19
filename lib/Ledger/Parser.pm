package Ledger::Parser;

# DATE
# VERSION

use 5.010001;
use strict;
use utf8;
use warnings;
use Carp;

use constant +{
    COL_TYPE => 0,

    COL_B_RAW => 1,

    COL_T_DATE  => 1,
    COL_T_EDATE => 2,
    COL_T_WS1   => 3,
    COL_T_STATE => 4,
    COL_T_WS2   => 5,
    COL_T_CODE  => 6,
    COL_T_WS3   => 7,
    COL_T_DESC  => 8,
    COL_T_NL    => 9,

    COL_P_WS1     => 1,
    COL_P_OPAREN  => 2,
    COL_P_ACCOUNT => 3,
    COL_P_CPAREN  => 4,
    COL_P_WS2     => 5,
    COL_P_AMOUNT  => 6,
    COL_P_WS3     => 7,
    COL_P_NOTE    => 8,
    COL_P_NL      => 9,
};

our $re_account_part = qr/(?:
                              [^\s:\[\(;]+?[ \t]??[^\s:\[\(;]*?
                          )+?/x; # don't allow double whitespace
our $re_account = qr/$re_account_part(?::$re_account_part)*/;
our $re_amount = qr/\d+/;

sub new {
    my ($class, %attrs) = @_;
    #$attrs{strict} //= 0; # check valid account names
    #$attrs{input_date_format} //= 'YYYY/MM/DD';
    bless \%attrs, $class;
}

sub _err {
    my ($self, $msg) = @_;
    croak join(
        "",
        @{ $self->{_include_stack} } ? "$self->{_include_stack}[0] " : "",
        "line $self->{_linum}: ",
        $msg
    );
}

sub _push_include_stack {
    require Cwd;

    my ($self, $path) = @_;

    # included file's path is based on the main (topmost) file
    if (@{ $self->{_include_stack} }) {
        require File::Spec;
        my (undef, $dir, $file) =
            File::Spec->splitpath($self->{_include_stack}[-1]);
        $path = File::Spec->rel2abs($path, $dir);
    }

    my $abs_path = Cwd::abs_path($path) or return [400, "Invalid path name"];
    return [409, "Recursive", $abs_path]
        if grep { $_ eq $abs_path } @{ $self->{_include_stack} };
    push @{ $self->{_include_stack} }, $abs_path;
    return [200, "OK", $abs_path];
}

sub _pop_include_stack {
    my $self = shift;

    die "BUG: Overpopped _pop_include_stack" unless @{$self->{_include_stack}};
    pop @{ $self->{_include_stack} };
}

sub _init_read {
    my $self = shift;

    $self->{_include_stack} = [];
}

sub _read_file {
    my ($self, $filename) = @_;
    open my $fh, "<", $filename
        or die "Can't open file '$filename': $!";
    binmode($fh, ":utf8");
    local $/;
    return ~~<$fh>;
}

sub read_file {
    my ($self, $filename) = @_;
    $self->_init_read;
    my $res = $self->_push_include_stack($filename);
    die "Can't read '$filename': $res->[1]" unless $res->[0] == 200;
    $res =
        $self->_read_string($self->_read_file($filename));
    $self->_pop_include_stack;
    $res;
}

sub read_string {
    my ($self, $str) = @_;
    $self->_init_read;
    $self->_read_string($str);
}

sub _read_string {
    my ($self, $str) = @_;

    my $res = [];

    my $in_xact;

    my @lines = split /^/, $str;
    local $self->{_linum} = 0;
  LINE:
    for my $line (@lines) {
        $self->{_linum}++;

        if ($in_xact && $line !~ /^\s/) {
            $in_xact = 0;
        }

        # blank line (B)
        if ($line !~ /\S/) {
            push @$res, [
                'B',
                $line, # COL_B_RAW
            ];
            next LINE;
        }

        # transaction line (T)
        if ($line =~ /^\d/) {
            $line =~ m<^(\d+[/-]\d+[/-]\d+)         # 1) actual date
                       (?: = (\d+[/-]\d+[/-]\d+))?  # 2) effective date
                       (?: (\s+) ([!*]))?           # 3) ws 4) state
                       (?: (\s+) \(([^\)]+)\))?     # 5) ws 6) code
                       (\s+) (\S.+?)                # 7) ws 8) desc
                       (\R?)\z                      # 9) nl
                      >x
                          or $self->_err("Invalid transaction line syntax");
            push @$res, ['T', $1, $2, $3, $4, $5, $6, $7, $8, $9];
            $in_xact = 1;
            next LINE;
        }

        # posting (P)
        # TODO: support @AMOUNT (per-unit posting cost)
        # TODO: support @@AMOUNT (complete posting cost)
        if ($in_xact && $line =~ /^\s/) {
            $line =~ m!^(\s+)              # 1) ws1
                       (\[|\()?            # 2) oparen
                       ($re_account)       # 3) account
                       (\]|\))?            # 4) cparen
                       (\s{2,})            # 5) ws2
                       ($re_amount)        # 6) amount
                       (?: (\s*) ;(.*?))?  # 7) ws 8) note
                       (\R?)\z             # 9) nl
                      !x
                          or $self->_err("Invalid posting line syntax");
            push @$res, ['P', $1, $2, $3, $4, $5, $6, $7, $8, $9];
            next LINE;
        }

        $self->_err("Invalid syntax");
    }

    # make sure we always end with newline
    if (@$res) {
        $res->[-1][-1] .= "\n"
            unless $res->[-1][-1] =~ /\R\z/;
    }

    require Config::IOD::Document;
    Config::IOD::Document->new(_parser=>$self, _parsed=>$res);
}

# old names, to be removed in the future
sub parse_file { goto &read_file }
sub parse { goto &read_string }

1;
# ABSTRACT: Parse Ledger journals

=head1 SYNOPSIS

 use Ledger::Parser;
 my $ledgerp = Ledger::Parser->new();

 # parse a file
 my $journal = $ledgerp->read_file("$ENV{HOME}/money.dat");

 # parse a string
 $journal = $ledgerp->read_string(<<EOF);
 ; -*- Mode: ledger -*-
 09/06 dinner
 Expenses:Food          $10.00
 Expenses:Tips         5000.00 IDR ; 5% tip
 Assets:Cash:Wallet

 2013/09/07 opening balances
 Assets:Mutual Funds:Mandiri  10,305.1234 MFEQUITY_MANDIRI_IAS
 Equity:Opening Balances

 P 2013/08/01 MFEQUITY_MANDIRI_IAS 1,453.8500 IDR
 P 2013/08/31 MFEQUITY_MANDIRI_IAS 1,514.1800 IDR
 EOF

See L<Ledger::Journal> for available methods for the journal object.


=head1 DESCRIPTION

This module parses Ledger journal into L<Ledger::Journal> object. See
http://ledger-cli.org/ for more on Ledger, the command-line double-entry
accounting system software.

Ledger 3 can be extended with Python, and this module only supports a subset of
Ledger format, so you might also want to take a look into the Python extension.
However, this module can also modify/write the journal, so it can be used e.g.
to insert transactions programmatically (which is my use case and the reason I
created this module).

This is an inexhaustive list of things that are not supported:

=over

=item * Automated transaction (line that begins with C<=>)

=item * Periodic transaction (line that begins with C<~>)

=item * Assert command

=item * C command (currency conversion)

=back


=head1 ATTRIBUTES


=head1 METHODS

=head2 new()

Create a new parser instance.

=head2 $ledgerp->read_file($filename) => obj

=head2 $ledgerp->read_string($str) => obj

=cut
