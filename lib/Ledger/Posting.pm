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
    'Ledger::Role::HaveCachedText' => {
	-alias => { as_string => '_as_string_main' },
	-excludes => 'as_string',
    },
    'Ledger::Role::Readable',
    'Ledger::Role::HaveReadableElementsList' => { -excludes => 'BUILD', },
    'Ledger::Role::HaveElements' => {
	-alias => { as_string => '_as_string_elements' },
	-excludes => [ 'as_string' ],
    },
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

    return ($line !~ /^\s+;/);
}

before 'load_from_reader' => sub {
    my $self = shift;
    my $reader = shift;

    my $line = $reader->pop_line;
    if ($line !~ m!
	^(\s+)                       # 1) ws1
	(\S.*?)                      # 2) account
	(?: (\s{2,}|\t)(\S.*?) )?    # 3) ws2 4) amount
	(?: (\s*) ;(.*?))?           # 5) ws3 6) note
	(\R?)\z                      # 7) nl
                      !x) {
	$reader->give_back_next_line($line);
	die Ledger::Exception::ParseError->new(
	    'line' => $line,
	    'parser_prefix' => $reader->error_prefix,
	    'message' => "not an initial posting line",
	    );
    }
    my $e;
    try {
	$self->ws1_str($1);
	$self->account_str($2);
	$self->ws2_str($3) if defined($3);
	$self->amount_str($4) if defined($4);
	$self->ws3_str($5) if defined($5);
	$self->note_str($6) if defined($6);
	$self->_cached_text($line);
    }
    catch (Ledger::Exception::ValueParseError $e) {
	my $msg=$e->message;
	$reader->give_back_next_line($line);
	die Ledger::Exception::ParseError->new(
	    'line' => $line,
	    'parser_prefix' => $reader->error_prefix,
	    'message' => "while reading posting: $msg",
	    );
    }
};

sub compute_text {
    my $self = shift;

    return $self->compute_text_from_values(
	$self->config->posting_format."\n",
	);
}

sub as_string {
    my $self = shift;
    return $self->_as_string_main
	.$self->_as_string_elements;
}

use Carp;
sub _err {
    my ($self, $msg) = @_;
    croak join(
        "",
        #@{ $self->{_include_stack} } ? "$self->{_include_stack}[0] " : "",
        #"line $self->{_linum}: ",
        $msg." in\n".$self->as_string,
	"from transaction\n",
	$self->parent->as_string,
    );
}

1;
