package Ledger::Journal::ApplyTag;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Journal::Element';

sub cleanup {}

has_value 'lastline' => (
    isa              => 'StrippedStr',
    default          => 'end apply tag',
    reset_on_cleanup => 1,
    );

sub end_line_re {
    my $self = shift;

    return qr/^end\s+apply\s+tag/;
}

with (
    'Ledger::Role::IsElementWrappingElements',
    );

has '+elements' => (
    isa      => 'ArrayRef[Ledger::Journal::Element]',
    );

has_value 'keyword' => (
    isa      => 'StrippedStr',
    required => 1,
    reset_on_cleanup => 1,
    default  => 'apply tag',
    );

has_value 'ws1' => (
    isa      => 'WS1',
    required  => 1,
    reset_on_cleanup => 1,
    default          => ' ',
    );

has_value 'tag' => (
    isa    => 'TaggedValue',
    required => 1,
    );

before 'load_from_reader' => sub {
    my $self = shift;
    my $reader = shift;

    my $line = $reader->next_line;
    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^apply\s+tag/,
	'parse_line_re' => qr<
	     ^(?<keyword>apply\s+tag)
	     (?<ws1>\s+)
	     (?<tag>.*\S)
	                    >x,
	'noaccept_error_msg' => "not starting an apply tag section",
	'accept_error_msg' => "invalid 'apply tag' line",
	'parse_value_error_msg' => "invalid data in 'apply tag' declaration",
	'store' => 'all', # endline wont be defined so wont be set
	);
    if (! $self->tag->isa('Ledger::Value::SubType::TaggedValue')) {
	die Ledger::Exception::ParseError->new(
	    'abortParsing' => 1,
	    'line' => $line,
	    'parser_prefix' => $reader->error_prefix,
	    'message' => "invalid tag in 'apply tag' line",
	    );
    }
};

sub compute_text {
    my $self = shift;
    return $self->keyword_str.$self->ws1_str.$self->tag_str."\n";
}

1;
