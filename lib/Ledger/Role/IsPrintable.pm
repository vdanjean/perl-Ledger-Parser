package Ledger::Role::IsPrintable;
use Moose::Role;
use namespace::sweep;

requires 'as_string';

use overload '""' => sub { shift->as_string() };

sub cleanup {}

1;
