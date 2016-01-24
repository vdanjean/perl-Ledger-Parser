package Ledger::Role::IsElementWithElements;
use Moose::Role;
use namespace::sweep;

with (
    'Ledger::Role::HaveCachedText' => {
	-alias => { as_string => '_as_string_main' },
	-excludes => 'as_string',
    },
    'Ledger::Role::Readable',
    'Ledger::Role::HaveReadableElementsList' => { -excludes => 'BUILD', },
    'Ledger::Role::HaveElements' => {
	-alias => { as_string => '_as_string_elements' },
	-excludes => [ 'as_string' ],
    },
    );

sub _readEnded {
    my $self = shift;
    my $reader = shift;
    my $line = $reader->next_line;

    return ($line !~ /\S/ || $line =~ /^\S/);
}

sub as_string {
    my $self = shift;
    return $self->_as_string_main
	.$self->_as_string_elements;
}

1;
