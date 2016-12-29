package Ledger::Util::Filter;

use constant ACCEPT => 0;
use constant FILTER => 1;
use constant FILTERSUB => 2;

use Exporter qw(import);
my @list = qw(ACCEPT FILTER FILTERSUB);
#our @EXPORT_OK = (@list, qw(toSymbol fromSymbol));
our @EXPORT_OK = @list;
our %EXPORT_TAGS = ( 'constants' => \@list, 'all' => \@EXPORT_OK );

1;
