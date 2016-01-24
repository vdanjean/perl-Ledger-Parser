package Ledger::Value::SubType::PostingAccount;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::sweep;
use Math::BigRat;
use Ledger::Util::ValueAttribute;
use Ledger::Util qw(:regexp);

with (
    'Ledger::Role::IsSubValue',
    );

has_value 'name' => (
    isa    => 'StrippedStr',
    required => 1,
    format_type => 'skip',
);

has 'kind' => (
    is       => 'rw',
    isa      => 'Ledger::Type::Posting::Kind',
    default  => Ledger::Posting::Kind::REAL,
    trigger  => sub {
	my $self=shift;
	$self->_value_updated(@_);
    },
    );

sub compute_text {
    my $self = shift;

    return Ledger::Posting::Kind->formatAccount(
	$self->kind,
	$self->name_str,
	);
    
    my $postingFormat = '@{name:%s}'; #$self->config->account_format;
    my @formatParams=();

    push @formatParams, $self->formatValueParams();
    
    push @formatParams, Ledger::Util->buildFormatParam(
	'name',
	'object' => $self,
	'value' => Ledger::Posting::Kind->formatAccount(
	    $self->kind,
	    $self->name_str,
	),
	);

    my $str=Ledger::Util->format(
	$postingFormat => {@formatParams}
	);
    if ($str->[0] != 200) {
	die($str->[1]);
    }
    $str->[1] =~ s/\s+$//;
    return $str->[1];
}

my $re_account=re_account;

sub parse_str {
    my ($self, $str) = @_;

    $self->die_bad_string(
	$str,
	'invalid account syntax')
	unless $str =~ /\A(
            (\[|\()?                     # 2) oparen
	    ($re_account)                # 3) account
	    (\]|\))?                     # 4) cparen
            )\z/x;

    $self->name_str($3);

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
	$self->kind(Ledger::Posting::Kind::REAL);
    } elsif ($oparen eq '[') {
	$self->kind(Ledger::Posting::Kind::VIRTUALBALANCED);
    } elsif ($oparen eq '(') {
	$self->kind(Ledger::Posting::Kind::VIRTUALUNBALANCED);
    } else {
	die "Argh, what happens?";
    }
}

1;
