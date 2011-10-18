package Ledger::Util;

use 5.010;
use strict;
use warnings;
use Exporter::Lite;
use Parse::Number::EN;

our @EXPORT    = qw($re_cmdity $re_comment $re_date $re_amount $re_number
                    $re_accpart $re_account0 $re_account);
our @EXPORT_OK = qw(parse_number);

our $re_comment   = qr/^(\s*;|[^0-9P]|\s*$)/x;
our $re_cmdity    = qr/(?:\w+|\$)/x; # XXX add other currency symbols
my  $re_dsep      = qr![/-]!;
our $re_date      = qr/(?:
                           (?:(?<y>\d\d|\d\d\d\d)$re_dsep)?
                           (?<m>\d{1,2})$re_dsep
                           (?<d>\d{1,2})
                       )/x;
our $re_number    = $Parse::Number::EN::Pat;
our $re_amount    = qr/(?:
                           (?:(?<cmdity>$re_cmdity)\s*(?<number>$re_number))|
                           (?:(?<number>$re_number)\s*(?<cmdity>$re_cmdity))|
                           (?:(?<number>$re_number))
                       )/x;
our $re_accpart   = qr/(?:(
                              (?:[^:\s]+[ \t][^:\s]*)|
                              [^:\s]+
                      ))+/x; # don't allow double space
our $re_account0  = qr/(?:$re_accpart(?::$re_accpart)*)/x;
our $re_account   = qr/(?<acc>$re_account0|\($re_account0\)|\[$re_account0\])/x;

sub parse_number {
    my $num = shift;
    $num =~ $re_number ? $num+0 : undef;
}

sub now {
    my $self = shift;
    state $mtime;
    state $cache;
    my $now = time;

    # cache "now" every hour
    if (!$mtime || $now-$mtime > 3600) {
        $cache = DateTime->now;
        $mtime = $now;
    }
    $cache;
}

sub parse_date {
    my ($self, $date) = @_;
    $self->_die("Invalid date") unless $date =~ $re_date;
    my $y = $+{y} // $self->now->year;
    DateTime->new(day => $+{d}, month => $+{m}, year => $y);
}

1;
