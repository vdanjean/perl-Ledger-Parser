package Ledger::Exception;
use Moose;
use namespace::sweep;


has 'message' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;

