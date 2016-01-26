package Ledger::Journal::Bucket;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

with (
    'Ledger::Role::HaveCachedText',
    'Ledger::Role::Readable',
    );

extends 'Ledger::Journal::Element';

has_value 'keyword' => (
    isa      => 'StrippedStr',
    required  => 1,
    reset_on_cleanup => 1,
    default          => 'bucket',
    );

has_value 'ws1' => (
    isa      => 'WS1',
    required  => 1,
    reset_on_cleanup => 1,
    default          => ' ',
    );

has_value 'name' => (
    isa    => 'AccountName',
    required => 1,
    );

sub load_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^bucket/,
	'parse_line_re' => qr<
	     ^(?<keyword>bucket)
	     (?<ws1>\s+)
	     (?<name>.*\S)
	                    >x,
	'noaccept_error_msg' => "not a bucket declaration",
	'accept_error_msg' => "invalid bucket declaration (missing account name?)",
	'parse_value_error_msg' => "invalid data in bucket declaration",
	'store' => 'all',
	);
};

sub compute_text {
    my $self = shift;
    return $self->keyword_str.$self->ws1_str.$self->name_str."\n";
}

1;
