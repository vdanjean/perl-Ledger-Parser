package Ledger::Account;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;
use Ledger::Util qw(:regexp);
use TryCatch;

extends 'Ledger::Journal::Element';

with (
    'Ledger::Role::IsElementWithElements',
    );

has '+elements' => (
    isa      => 'ArrayRef[Ledger::Account::Element]',
    );

sub _setupElementKinds {
    return [
	#'Ledger::Account::Note',
	#'Ledger::Account::Alias',
	#'Ledger::Account::Payee',
	#'Ledger::Account::Check',
	#'Ledger::Account::Assert',
	#'Ledger::Account::Eval',
	#'Ledger::Account::Print',
	#'Ledger::Account::Default',
	];
}

has_value 'keyword' => (
    isa      => 'StrippedStr',
    required  => 1,
    reset_on_cleanup => 1,
    default          => 'account',
    );

has_value 'ws1' => (
    isa      => 'WS1',
    required  => 1,
    reset_on_cleanup => 1,
    default          => ' ',
    );

has_value 'name' => (
    isa    => 'StrippedStr',
    required => 1,
    );

my $re_account=re_account;

before 'load_from_reader' => sub {
    my $self = shift;
    my $reader = shift;

    my $line = $reader->pop_line;
    if ($line !~ m
	<^(account)                     # 1) actual date
	(\s+)                           # 2) ws
	($re_account) \s*               # 3) account_name
	(\R?)\z                         # 4) nl
	>x) {
	$reader->give_back_next_line($line);
	if ($line =~ /^account(\s|(\R?\z))/) {
	    die Ledger::Exception::ParseError->new(
		'line' => $line,
		'parser_prefix' => $reader->error_prefix,
		'message' => "invalid initial account line (bad account name?)",
		'abortParsing' => 1,
		);
	} else {
	    die Ledger::Exception::ParseError->new(
		'line' => $line,
		'parser_prefix' => $reader->error_prefix,
		'message' => "not an initial account line",
		);
	}
    }
    my $e;
    try {
	$self->keyword_str($1);
	$self->ws1_str($2);
	$self->name_str($3);
	$self->_cached_text($line);
    }
    catch (Ledger::Exception::ValueParseError $e) {
	my $msg=$e->message;
	$reader->give_back_next_line($line);
	die Ledger::Exception::ParseError->new(
	    'line' => $line,
	    'parser_prefix' => $reader->error_prefix,
	    'message' => "while reading account: $msg",
	    'abortParsing' => 1,
	    );
    }
};

sub compute_text {
    my $self = shift;

    return $self->keyword_str.$self->ws1_str.$self->name_str."\n";
}

#use 
override 'validate' => sub {
    my $self = shift;

    super();

    # TODO: check number of sublines for each types
};

1;
