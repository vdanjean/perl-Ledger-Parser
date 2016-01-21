package Ledger::Exception::Validation;
use Moose;
use namespace::sweep;
use Ledger::Types;

extends 'Ledger::Exception';

has 'fromElement' => (
    is       => 'ro',
    isa      => 'Ledger::Element',
    required => 1,
    );

has 'errorLevel' => (
    is       => 'ro',
    isa      => 'Ledger::Type::ErrorLevel',
    required => 1,
    default  => 'error',
    );

1;
