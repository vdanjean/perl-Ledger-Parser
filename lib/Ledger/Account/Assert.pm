package Ledger::Account::Assert;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

sub keyword_name {
    return 'assert';
}

sub end_parse_line_re {
    return qr/(?<assert>.*\S)/;
}

with (
    'Ledger::Role::IsSimpleSubElement',
    );

extends 'Ledger::Account::Element';

has_value 'assert' => (
    isa      => 'StrippedStr',
    );

1;
