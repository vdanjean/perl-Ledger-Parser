package Ledger::Role::Element::SubDirective::Base;
use Moose::Role;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

requires 'subdirective_name';

with (
    'Ledger::Role::Element::Layout::OneLine',
    );

has_value_indented_line 'ws1';

has_value_constant 'subdirective' => (
    default  => sub {
	my $self = shift;
	return $self->element->subdirective_name;
    },
    order    => -50,
    );

has_value_separator_simple 'ws2' => (
    order    => -30,
    );

1;
