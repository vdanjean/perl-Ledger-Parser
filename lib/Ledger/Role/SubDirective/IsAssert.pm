package Ledger::Role::SubDirective::IsCheck;
use Moose::Role;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

sub keyword_name {
    return 'assert';
}

sub end_parse_line_re {
    return qr/(?<assert>.*\S)/;
}

with (
    'Ledger::Role::SubDirective::Simple',
    );

has_value 'assert' => (
    isa      => 'StrippedStr',
    );

1;
