package Ledger::Account::Check;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;
use Ledger::Util qw(:regexp);

sub keyword_name {
    return 'check';
}

sub end_parse_line_re {
    return qr/(?<check>.*?)/;
}

with (
    'Ledger::Role::IsSimpleSubElement',
    );

extends 'Ledger::Account::Element';

has_value 'check' => (
    isa      => 'StrippedStr',
    );

1;
