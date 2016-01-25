package Ledger::Role::IsNote;
use Moose::Role;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

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
    );

has_value 'note' => (
    isa      => 'MetaData',
    );

sub load_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_re' => qr/^\s+;/,
	'parse_line_re' => qr<
	     ^(?<ws1>\s+);
             (?<note>.*?)
	                    >x,
	'noaccept_error_msg' => "not a comment line",
	'store' => 'all',
	);
};

sub compute_text {
    my $self = shift;
    return $self->ws1_str.';'.$self->note_str."\n";
}

1;

