package Ledger::Role::Element::SubDirective::IsAssert;
use Moose::Role;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

sub subdirective_name {
    return 'assert';
}

sub end_parse_line_re {
    return qr/(?<assert>.*\S)/;
}

with (
    'Ledger::Role::Element::SubDirective::Simple',
    );

has_value 'assert' => (
    isa      => 'StrippedStr',
    );

1;
