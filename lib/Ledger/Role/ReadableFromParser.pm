package Ledger::Role::ReadableFromParser;
use Moose::Role;

requires 'load_from_parser';

sub BUILD {}

after 'BUILD' => sub {
    my $self = shift;
    my $args = shift;

    if (exists($args->{'parser'})) {
	$self->load_from_parser($args->{'parser'});
    }
};

1;

