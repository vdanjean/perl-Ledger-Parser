package Ledger::Value::PostingAccount;
use Moose;
use namespace::sweep;
use Ledger::Types;
use Ledger::Util;
use Ledger::Value::SubType::PostingAccount;
use utf8;

extends 'Ledger::Value';

with (
    'Ledger::Role::IsValue',
    );

has '+value' => (
    isa      => 'Ledger::Value::SubType::PostingAccount',
    required => 1,
    builder  => '_null_value',
    );

# after because we define the 'value' method with 'around'
with (
    'Ledger::Role::HaveSubValues',
    );

sub _null_value {
    my $self = shift;
    Ledger::Value::SubType::PostingAccount->new(
	'parent' => $self,
	);
}

our $re_account_part = qr/(?:
                              [^\s:\[\(;]+?[ \t]??[^\s:\[\(;]*?
                          )+?/x; # don't allow double whitespace
our $re_account = qr/$re_account_part(?::$re_account_part)*/;

sub _parse_str {
    my ($self, $str) = @_;

    $self->die_bad_string(
	$str,
	'invalid account syntax')
	unless $str =~ /\A(
            (\[|\()?                     # 2) oparen
	    ($re_account)                # 3) account
	    (\]|\))?                     # 4) cparen
            )\z/x;

    $self->value->name_str($3);

    # brace must match
    my ($oparen, $cparen) = ($2 // '', $4 // '');
    unless (!$oparen && !$cparen ||
	    $oparen eq '[' && $cparen eq ']' ||
	    $oparen eq '(' && $cparen eq ')') {
	$self->die_bad_string(
	    $str,
	    "invalid account syntax:".
	    " parentheses/braces around account don't match");
    }
    if ($oparen eq '') {
	$self->value->kind(Ledger::Posting::Kind::REAL);
    } elsif ($oparen eq '[') {
	$self->value->kind(Ledger::Posting::Kind::VIRTUALBALANCED);
    } elsif ($oparen eq '(') {
	$self->value->kind(Ledger::Posting::Kind::VIRTUALUNBALANCED);
    } else {
	die "Argh, what happens?";
    }
}

1;
