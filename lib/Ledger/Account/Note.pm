package Ledger::Account::Note;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;
use Ledger::Util qw(:regexp);

sub keyword_name {
    return 'note';
}

sub end_parse_line_re {
    return qr/(?<note>.*?)/;
}

with (
    'Ledger::Role::IsSimpleSubElement',
    );

extends 'Ledger::Account::Element';

has_value 'note' => (
    isa      => 'StrippedStr',
    );

1;
