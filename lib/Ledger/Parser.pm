package Ledger::Parser;

# DATE
# VERSION

use 5.010001;
use strict;
use utf8;
use warnings;
use Carp;

use Time::Local;

use constant +{
    COL_TYPE => 0,

    COL_B_RAW => 1,

    COL_T_DATE    => 1,
    COL_T_EDATE   => 2,
    COL_T_WS1     => 3,
    COL_T_STATE   => 4,
    COL_T_WS2     => 5,
    COL_T_CODE    => 6,
    COL_T_WS3     => 7,
    COL_T_DESC    => 8,
    COL_T_WS4     => 7,
    COL_T_COMMENT => 8,
    COL_T_NL      => 9,

    COL_P_WS1     => 1,
    COL_P_OPAREN  => 2,
    COL_P_ACCOUNT => 3,
    COL_P_CPAREN  => 4,
    COL_P_WS2     => 5,
    COL_P_AMOUNT  => 6,
    COL_P_WS3     => 7,
    COL_P_COMMENT => 8,
    COL_P_NL      => 9,

    COL_C_CHAR    => 1,
    COL_C_COMMENT => 2,
    COL_C_NL      => 3,

    COL_TC_WS1     => 1,
    COL_TC_COMMENT => 2,
    COL_TC_NL      => 3,
};

# note: $RE_xxx is capturing, $re_xxx is non-capturing
our $re_date = qr!(?:\d{4}[/-])?\d{1,2}[/-]\d{1,2}!;
our $RE_date = qr!(?:(\d{4})[/-])?(\d{1,2})[/-](\d{1,2})!;

our $re_account_part = qr/(?:
                              [^\s:\[\(;]+?[ \t]??[^\s:\[\(;]*?
                          )+?/x; # don't allow double whitespace
our $re_account = qr/$re_account_part(?::$re_account_part)*/;
our $re_commodity = qr/[A-Z_]+[A-Za-z_]*|[\$£€¥]/;
our $re_amount = qr/(?:-?)
                    (?:$re_commodity)?
                    \s* (?:-?[0-9,]+\.?[0-9]*)
                    \s* (?:$re_commodity)?
                   /x;
our $RE_amount = qr/(-?)
                    ($re_commodity)?
                    \s* (-?[0-9,]+\.?[0-9]*)
                    \s* ($re_commodity)?
                   /x;

sub new {
    my ($class, %attrs) = @_;

    $attrs{input_date_format} //= 'YYYY/MM/DD';
    $attrs{year} //= (localtime)[5] + 1900;
    #$attrs{strict} //= 0; # check valid account names

    # checking
    $attrs{input_date_format} =~ m!\A(YYYY/MM/DD|YYYY/DD/MM)\z!
        or croak "Invalid input_date_format: choose YYYY/MM/DD or YYYY/DD/MM";

    bless \%attrs, $class;
}

sub _parse_date {
    my ($self, $str) = @_;
    croak "Invalid date '$str'" unless $str =~ /\A(?:$RE_date)\z/;

    if ($self->{input_date_format} eq 'YYYY/MM/DD') {
        return timelocal(0, 0, 0, $3, $2-1, ($1)-1900);
    } else {
        return timelocal(0, 0, 0, $2, $3-1, ($1)-1900);
    }
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

    my $in_tx;

    my @lines = split /^/, $str;
    local $self->{_linum} = 0;
  LINE:
    for my $line (@lines) {
        $self->{_linum}++;

        # transaction is broken by an empty/all-whitespace line or a
        # non-indented line
        if ($in_tx && $line !~ /\S/ || $line =~ /^\S/) {
            $in_tx = 0;
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
            $line =~ m<^($re_date)                     # 1) actual date
                       (?: = $re_date)?                # 2) effective date
                       (?: (\s+) ([!*]) )?             # 3) ws 4) state
                       (?: (\s+) \(([^\)]+)\) )?       # 5) ws 6) code
                       (\s+) (\S.*?)                   # 7) ws 8) desc
                       (?: (\s{2,}) ;(\S.+?) )?        # 9) ws 10) comment
                       (\R?)\z                         # 11) nl
                      >x
                          or $self->_err("Invalid transaction line syntax");
            push @$res, ['T', $1, $2, $3, $4, $5, $6, $7, $8, $9];
            $in_tx = 1;
            next LINE;
        }

        # comment line (C)
        if ($line =~ /^([;#%|*])(.*?)(\R?)\z/) {
            push @$res, ['C', $1, $2, $3];
            next LINE;
        }

        # transaction comment (TC)
        if ($in_tx && $line =~ /^(\s+);(.*?)(\R?)\z/) {
            push @$res, ['TC', $1, $2, $3];
            next LINE;
        }

        # posting (P)
        if ($in_tx && $line =~ /^\s/) {
            $line =~ m!^(\s+)                       # 1) ws1
                       (\[|\()?                     # 2) oparen
                       ($re_account)                # 3) account
                       (\]|\))?                     # 4) cparen
                       (?: (\s{2,})($re_amount) )?  # 5) ws2 6) amount
                       (?: (\s*) ;(.*?))?           # 7) ws 8) note
                       (\R?)\z                      # 9) nl
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
 my $ledgerp = Ledger::Parser->new(
     # year              => undef,        # default: current year
     # input_date_format => 'YYYY/MM/DD', # or 'YYYY/DD/MM',
 );

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
Ledger syntax, so you might also want to take a look into the Python extension.
However, this module can also modify/write the journal, so it can be used e.g.
to insert transactions programmatically (which is my use case and the reason I
created this module).

This is an inexhaustive list of things that are not currently supported:

=over

=item * Costs & prices

For example, things like:

 2012-04-10 My Broker
    Assets:Brokerage            10 AAPL @ $50.00
    Assets:Brokerage:Cash

=item * Automated transaction (line that begins with C<=>)

=item * Periodic transaction (line that begins with C<~>)

=item * Various commands

Including but not limited to: assert, C (currency conversion), ...

=back


=head1 ATTRIBUTES

=head2 input_date_format => str ('YYYY/MM/DD' or 'YYYY/DD/MM')

Ledger accepts dates in the form of yearless (e.g. 01/02, 3-12) or with 4-digit
year (e.g. 2015/01/02, 2015-3-12). Month and day can be single- or
double-digits. Separator is either C<-> or C</>.

When year is omitted, year will be retrieved from the C<year> attribute.

The default format is month before day (C<YYYY/MM/DD>), but you can also use day
before month (C<YYYY/DD/MM>).

=head2 year => int (default: current year)

Only used when encountering a date without year.

=head2


=head1 METHODS

=head2 new(%attrs) => obj

Create a new parser instance.

=head2 $ledgerp->read_file($filename) => obj

=head2 $ledgerp->read_string($str) => obj

=cut
