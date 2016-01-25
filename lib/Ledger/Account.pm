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
	'Ledger::Account::Alias',
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
    isa    => 'AccountName',
    required => 1,
    );

my $re_account=re_account;

before 'load_from_reader' => sub {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^account/,
	'parse_line_re' => qr<
	     ^(?<keyword>account)
	     (?<ws1>\s+)
	     (?<name>.*\S)
	                    >x,
	'noaccept_error_msg' => "not starting an account block",
	'accept_error_msg' => "invalid account line (missing account name?)",
	'parse_value_error_msg' => "invalid data in account line",
	'store' => 'all',
	);
    return;
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
