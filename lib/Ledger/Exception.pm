package Ledger::Exception;
use Moose;
use namespace::sweep;

with (
    'Ledger::Role::IsPrintable',
    );

has 'message' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub as_string {
    my $self=shift;
    return "Ledger::Exception::ValueParseError: ".$self->message;
}

1;

