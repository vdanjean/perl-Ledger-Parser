package Ledger::Account::Alias;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

sub keyword_name {
    return 'alias';
}

sub end_parse_line_re {
    return qr/(?<name>.*\S)/;
}

with (
    'Ledger::Role::IsSimpleSubElement',
    );

extends 'Ledger::Account::Element';

has_value 'name' => (
    isa      => 'AccountName',
    );

1;


