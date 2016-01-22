package Ledger::Value::PostingAccount;
use Moose;
use namespace::sweep;
use Ledger::Types;
use Ledger::Util;
use Ledger::Types::PostingAccount;
use utf8;

extends 'Ledger::Value';

with (
    'Ledger::Role::IsValue',
    );

has '+value' => (
    isa      => 'Ledger::Types::PostingAccount',
    required => 1,
    default  => sub {
	my $self = shift;
	Ledger::Types::PostingAccount->new(
	    'parent' => $self,
	    );
    },
    );

sub _compute_text {
    my $self = shift;

    return $self->value->compute_text;
}

our $re_account_part = qr/(?:
                              [^\s:\[\(;]+?[ \t]??[^\s:\[\(;]*?
                          )+?/x; # don't allow double whitespace
our $re_account = qr/$re_account_part(?::$re_account_part)*/;

sub _parse_account {
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
	die_bad_string(
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


around 'value' => sub {
    my $orig = shift;
    my $self = shift;
    
    return $self->$orig()
	unless @_;
    
    my $account = shift;
    if (ref(\$account) eq "SCALAR") {
	# assuming a String we will try to convert
	$self->_parse_account($account);
	return ;
    }
    return $self->$orig($account);
};

before 'cleanup' => sub {
    my $self = shift;
    $self->value->cleanup(@_);
};

1;
