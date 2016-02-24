package Ledger::Account;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;
use Ledger::Util qw(:regexp);
use TryCatch;

extends 'Ledger::Journal::Element';

with (
    'Ledger::Role::Element::Layout::MultiLines::List',
    );

has '+elements' => (
    isa      => 'ArrayRef[Ledger::Account::Element]',
    );

sub _setupElementKinds {
    return [
	'Ledger::Account::Note',
	'Ledger::Account::Alias',
	#'Ledger::Account::Payee',
	'Ledger::Account::Check',
	'Ledger::Account::Assert',
	#'Ledger::Account::Eval',
	#'Ledger::Account::Print',
	#'Ledger::Account::Default',
	];
}

has_value_directive 'account';

has_value_separator_simple 'ws1';

has_value 'name' => (
    isa    => 'AccountName',
    required => 1,
    );

my $re_account=re_account;

sub load_values_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^account/,
	'parse_line_re' => qr<
	     ^(?<directive>account)
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

#use 
override 'validate' => sub {
    my $self = shift;

    super();

    # TODO: check number of sublines for each types
};

1;

######################################################################
package Ledger::Account::Alias;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

sub subdirective_name {
    return 'alias';
}

sub end_parse_line_re {
    return qr/(?<name>.*\S)/;
}

with (
    'Ledger::Role::Element::SubDirective::Simple',
    );

extends 'Ledger::Account::Element';

has_value 'name' => (
    isa      => 'AccountName',
    );

1;

######################################################################
package Ledger::Account::Assert;
use Moose;
use namespace::sweep;

extends 'Ledger::Account::Element';

with (
    'Ledger::Role::Element::SubDirective::IsAssert',
    );

1;

######################################################################
package Ledger::Account::Check;
use Moose;
use namespace::sweep;

extends 'Ledger::Account::Element';

with (
    'Ledger::Role::Element::SubDirective::IsCheck',
    );

1;

######################################################################
package Ledger::Account::Note;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

sub subdirective_name {
    return 'note';
}

sub end_parse_line_re {
    return qr/(?<note>.*?)/;
}

with (
    'Ledger::Role::Element::SubDirective::Simple',
    );

extends 'Ledger::Account::Element';

has_value 'note' => (
    isa      => 'StrippedStr',
    );

1;
