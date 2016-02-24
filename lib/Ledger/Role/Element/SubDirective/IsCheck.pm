package Ledger::Role::Element::SubDirective::IsCheck;
use Moose::Role;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

sub subdirective_name {
    return 'check';
}

sub end_parse_line_re {
    return qr/(?<check>.*?)/;
}

with (
    'Ledger::Role::Element::SubDirective::Simple',
    );

has_value 'check' => (
    isa      => 'StrippedStr',
    );

1;
