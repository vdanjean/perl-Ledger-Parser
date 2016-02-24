package Ledger::Role::Element::Layout::MultiLines::List;
use Moose::Role;
use namespace::sweep;

with (
    'Ledger::Role::Element::Layout::WithSubElements',
    'Ledger::Role::HaveElements' => {
	-alias => { as_string => '_as_string_elements' },
	-excludes => [ 'as_string' ],
    },
    'Ledger::Role::HaveReadableElementsList' => { -excludes => 'BUILD', },
    );

sub _readEnded {
    my $self = shift;
    my $reader = shift;
    my $line = $reader->next_line;

    return (!defined($line) || $line !~ /\S/ || $line =~ /^\S/);
}

1;
