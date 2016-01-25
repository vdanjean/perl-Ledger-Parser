package Ledger::Journal::Note;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

with (
    'Ledger::Role::HaveCachedText',
    'Ledger::Role::Readable',
    );

extends 'Ledger::Journal::Element';

has_value 'commentchar' => (
    isa           => 'StrippedStr',
    required      => 1,
    default       => ';',
    );

has_value 'ws1' => (
    isa              => 'WS0',
    required         => 1,
    reset_on_cleanup => 1,
    default          => ' ',
);

has_value 'comment' => (
    isa    => 'EndStrippedStr',
);

sub load_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_re' => qr/^[;#%|*]/,
	'parse_line_re' => qr<
	     ^(?<commentchar>[;#%|*])
             (?<ws1>\s*)
             (?<comment>.*?)
	                    >x,
	'noaccept_error_msg' => "not a comment line",
	'store' => 'all',
	);
};

sub compute_text {
    my $self = shift;
    return $self->commentchar_str.$self->ws1_str.$self->comment_str."\n";
}

1;
