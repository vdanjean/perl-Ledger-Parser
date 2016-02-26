package Ledger::Journal::ApplyTag;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Journal::Element';

with (
    'Ledger::Role::Element::Layout::WithClosingElement',
    );

has '+elements' => (
    isa      => 'ArrayRef[Ledger::Journal::Element|Ledger::Journal::ApplyTag::EndLine]',
    );

has_value_directive 'apply tag';

has_value_separator_simple 'ws1';

has_value 'appliedTag' => (
    isa    => 'TaggedValue',
    required => 1,
    );

sub load_values_from_reader {
    my $self = shift;
    my $reader = shift;

    my $line = $reader->next_line;
    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^apply\s+tag/,
	'parse_line_re' => qr<
	     ^(?<directive>apply\s+tag)
	     (?<ws1>\s+)
	     (?<appliedTag>.*\S)
	                    >x,
	'noaccept_error_msg' => "not starting an apply tag section",
	'accept_error_msg' => "invalid 'apply tag' line",
	'parse_value_error_msg' => "invalid data in 'apply tag' declaration",
	'store' => 'all', # lastline wont be defined so wont be set
	);
    if (! $self->appliedTag->isa('Ledger::Value::SubType::TaggedValue')) {
	die Ledger::Exception::ParseError->new(
	    'abortParsing' => 1,
	    'line' => $line,
	    'parser_prefix' => $reader->error_prefix,
	    'message' => "invalid tag in 'apply tag' line",
	    );
    }
}

###################################
# TAG management
with (
    'Ledger::Role::HaveTags',
    );

sub _collect_tags {
    my $self = shift;
    $self->_reset_tags($self->appliedTag->tags);
}
    
1;

######################################################################
package Ledger::Journal::ApplyTag::EndLine;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Element';

with (
    'Ledger::Role::Element::Layout::OneLine',
    );

has_value_directive 'end apply tag';

sub load_values_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_line_re' => qr/^end\s+apply\s+tag\s*/,
	'parse_line_re' => qr /^
                (?<directive>end\s+apply\s+tag)
                \s*
                           /x,
	'noaccept_error_msg' => "not closing 'apply tag' section",
	'accept_error_msg' => "invalid closing 'apply tag' section",
	'store' => 'all',
	);
    return;
};
