package Ledger::Account::Note;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;
use Ledger::Util qw(:regexp);

with (
    'Ledger::Role::HaveCachedText',
    'Ledger::Role::Readable',
    'Ledger::Role::HaveValues',
    );

extends 'Ledger::Account::Element';

has_value 'ws1' => (
    isa      => 'WS1',
    required => 1,
    default  => '    ',
    reset_on_cleanup => 1,    
    );

has_value 'ws2' => (
    isa      => 'WS1',
    required => 1,
    default  => ' ',
    reset_on_cleanup => 1,    
    );

has_value 'note' => (
    isa      => 'StrippedStr',
    );

sub load_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^\s+note/,
	'parse_line_re' => qr /^
                (?<ws1>\s+)
                note
                (?<ws2>\s+)
                (?<note>.*?)
                           /x,
	'store' => 'all',
	);
    return;
};

sub compute_text {
    my $self = shift;
    return $self->ws1_str.'note'.$self->ws2_str.$self->note_str."\n";
}

1;