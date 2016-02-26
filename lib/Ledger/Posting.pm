package Ledger::Posting;
use Moose;
use namespace::sweep;
use Ledger::Types;
use Ledger::Util;
use Ledger::Util::ValueAttribute;
use TryCatch;
use utf8;

extends 'Ledger::Transaction::Element';

with (
    'Ledger::Role::IsElementWithElements',
    );

has '+elements' => (
    isa      => 'ArrayRef[Ledger::Posting::Element]',
    );

sub _setupElementKinds {
    return [
	'Ledger::Posting::Note',
	];
}

has_value 'ws1' => (
    isa              => 'WS1',
    required         => 1,
    reset_on_cleanup => 1,
    default          => '    ',
    );

has_value 'account' => (
    isa      => 'PostingAccount',
    required => 1,
    );

has_value 'ws2' => (
    isa              => 'WS2',
    required         => 1,
    reset_on_cleanup => 1,
    default          => '  ',
    );

has_value 'amount' => (
    isa      => 'PostingAmount',
    );

has_value 'ws3' => (
    isa              => 'WS0',
    required         => 1,
    reset_on_cleanup => 1,
    default          => '  ',
    );

has_value 'note' => (
    isa      => 'MetaData',
    );

sub _readEnded {
    my $self = shift;
    my $reader = shift;
    my $line = $reader->next_line;

    return (!defined($line) || $line !~ /^\s+;/);
}

before 'load_from_reader' => sub {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_re' => qr/^\s+[^;]/,
	'parse_line_re' => qr<
	    ^(?<ws1>\s+)
	    (?<account>\S.*?)
	    (?: (?<ws2>\s{2,}|\t)(?<amount>\S.*?) )?
	    (?: (?<ws3>\s*) ;(?<note>.*?))?
	                    >x,
	'accept_error_msg' => "invalid posting line",
	'noaccept_error_msg' => "not a posting line",
	'parse_value_error_msg' => "invalid data in posting line",
	'store' => 'all',
	);
    1;
};

sub compute_text {
    my $self = shift;

    return $self->compute_text_from_values(
	$self->config->posting_format."\n",
	);
}

###################################################################
# TAG management
with (
    'Ledger::Role::Element::AppliedTags',
    );

sub _collect_tags {
    my $self = shift;

    my $val_it = $self->valuesIterator(
	'select-value' => sub {
	    my $obj = shift;
	    return $obj->isa("Ledger::Value::MetaData")
		&& $obj->value->does("Ledger::Role::HaveTags");
	}
	);
    $self->_reset_tags($self->parent->tags);
    while (my $tag = $val_it->next) {
	$self->_merge_tags($tag->value);
    }
}
    
1;
