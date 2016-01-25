package Ledger::Role::IsSimpleSubElement;
use Moose::Role;
use namespace::sweep;

requires 'end_parse_line_re';

with (
    'Ledger::Role::IsSubElement',
    );

sub load_from_reader {
    my $self = shift;
    my $reader = shift;

    my $end_parse_line_re = $self->end_parse_line_re;
    my $keyword_re = $self->keyword_name;
    $keyword_re = qr/$keyword_re/;
    
    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^\s+$keyword_re/,
	'parse_line_re' => qr /^
                (?<ws1>\s+)
                (?<keyword>$keyword_re)
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
