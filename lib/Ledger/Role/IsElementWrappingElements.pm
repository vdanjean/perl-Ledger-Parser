package Ledger::Role::IsElementWrappingElements;
use Moose::Role;
use namespace::sweep;

requires 'end_line_re';
requires 'lastline_str';
requires 'has_lastline';

sub numlines {
    return 2;
}

with (
    'Ledger::Role::HaveCachedText' => {
	-alias => { as_string => '_as_string_main' },
	-excludes => 'as_string',
    },
    'Ledger::Role::Readable',
    'Ledger::Role::HaveReadableElementsFromParent',
    'Ledger::Role::HaveElements' => {
	-alias => { as_string => '_as_string_elements' },
	-excludes => [ 'as_string' ],
    },
    );

sub _readEnded {
    my $self = shift;
    my $reader = shift;
    my $line = $reader->next_line;

    if (!defined($line)) {
	return 1;
    }
    my $end_line_re=$self->end_line_re;
    if ($line =~ /($end_line_re)\s*(?<NL>\R?)\z/) {
	$self->lastline_str($1);
	$reader->pop_line;
	return 1;
    }
    return 0;
}

before 'load_from_reader' => sub {
    my $self = shift;
    my $reader = shift;

    $self->_lastline_rawvalue->_reset;
};

sub as_string {
    my $self = shift;
    my $append="";
    if ($self->has_lastline) {
	$append=$self->lastline_str."\n";
    }
    return $self->_as_string_main
	.$self->_as_string_elements
	.$append;
}

1;
