package Ledger::Posting::Note;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

with (
    'Ledger::Role::Element::IsNote',
    );

extends 'Ledger::Posting::Element';

has_value '+ws1' => (
    isa      => 'WS1',
    required => 1,
    default  => '        ',
    reset_on_cleanup => 1,    
    );

1;
