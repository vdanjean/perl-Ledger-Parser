package Ledger::Role::Readable;
use Moose::Role;
use namespace::sweep;

with 'Ledger::Role::NeedBUILD';

requires 'load_from_reader';

after 'BUILD' => sub {
    my $self = shift;
    my $args = shift;

    if (exists($args->{'reader'})) {
	$self->load_from_reader($args->{'reader'});
    }
};

1;

