package Ledger::Role::Config;
use Moose::Role;
use namespace::sweep;
use Moose::Util::TypeConstraints;

has 'input_date_format' => (
    is          => 'rw',
    isa         => enum([qw[ YYYY/MM/DD YYYY/DD/MM ]]),
    default     => "YYYY/MM/DD",
    );

has 'date_format' => (
    is          => 'rw',
    isa         => 'Str',
    default     => '%Y-%m-%d',
    );

has 'year' => (
    is          => 'rw',
    isa         => 'Num',
    default     => (localtime)[5] + 1900,
    );

has 'transaction_format' => (
    is          => 'rw',
    isa         => 'Str',
    default     => '@{date:%s}@{auxdate:=%s:%s}@{ws1:%s}@{state:%s: }@{ws2:%s}@{code:(%s) :%s}'.
    '@{description:%s}@{ws4:%s}@{note:;: :}@{ws5:%s}@{note:%s}',
    );

has 'posting_format' => (
    is          => 'rw',
    isa         => 'Str',
    default     => '@{ws1:%s}@{account:%-35s}@{ws2:%s}@{amount:%s:%13s}'.
    '@{ws3:%s}@{note:;: :}@{ws4:%s}@{note:%s}',
    );

has 'amount_format' => (
    is          => 'rw',
    isa         => 'Str',
    default     => '@{amount:%10.2f:%10s:%7d   }@{commodity: %-3s}',
    );

has 'die_on_first_error' => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 0,
    lazy        => 1,
    );

has 'die_if_parsing_error' => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 1,
    lazy        => 1,
    );

has 'display_errors' => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 1,
    lazy        => 1,
    );

1;

