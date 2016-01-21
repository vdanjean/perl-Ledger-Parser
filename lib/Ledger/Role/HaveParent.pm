package Ledger::Role::HaveParent;
use Moose::Role;
use Ledger::Role::HaveElements;
use Ledger::Role::HaveValues;

has 'parent' => (
    is        => 'ro',
    isa       => 'Ledger::Role::HaveElements|Ledger::Role::HaveValues',
    required  => 1,
    weak_ref  => 1,
    );

sub journal {
    my $self = shift;
    return $self->parent->journal;
}

sub config {
    my $self = shift;
    return $self->journal->config;
}

1;

