package Ledger::Role::IsSubElement;
use Moose::Role;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

requires 'keyword_name';

with (
    'Ledger::Role::HaveCachedText',
    'Ledger::Role::Readable',
    'Ledger::Role::HaveValues',
    );

has_value 'ws1' => (
    isa      => 'WS1',
    required => 1,
    default  => '    ',
    reset_on_cleanup => 1,
    order    => -30,
    );

has_value 'subcmd' => (
    isa      => 'Constant',
    required => 1,
    default  => sub {
	my $self = shift;
	return $self->element->keyword_name;
    },
    reset_on_cleanup => 1,
    order    => -20,
    );

has_value 'ws2' => (
    isa      => 'WS1',
    required => 1,
    default  => ' ',
    reset_on_cleanup => 1,
    order    => -10,
    );

1;
