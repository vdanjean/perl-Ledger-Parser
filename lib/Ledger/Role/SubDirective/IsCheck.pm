package Ledger::Role::SubDirective::IsCheck;
use Moose::Role;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

sub keyword_name {
    return 'check';
}

sub end_parse_line_re {
    return qr/(?<check>.*?)/;
}

with (
    'Ledger::Role::SubDirective::Simple',
    );

has_value 'check' => (
    isa      => 'StrippedStr',
    );

1;
