package Ledger::Role::Element::SubDirective::Simple;
use Moose::Role;
use namespace::sweep;

requires 'end_parse_line_re';

with (
    'Ledger::Role::Element::SubDirective::Base',
    );

sub load_values_from_reader {
    my $self = shift;
    my $reader = shift;

    my $end_parse_line_re = $self->end_parse_line_re;
    my $subdirective_re = $self->subdirective_name;
    $subdirective_re = qr/$subdirective_re/;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^\s+$subdirective_re/,
	'parse_line_re' => qr /^
                (?<ws1>\s+)
                (?<subdirective>$subdirective_re)
                (?<ws2>\s+)
                $end_parse_line_re
                           /x,
	'store' => 'all',
	);
    return;
};

sub compute_text {
    my $self = shift;
    return join('', (map {
	my $name_str=$_.'_str';
	$self->$name_str
		     } $self->get_all_value_names))."\n";
}

1;
