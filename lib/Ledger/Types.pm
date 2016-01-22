package Ledger::Types;
use Moose::Util::TypeConstraints;
use namespace::sweep;
use Ledger::Posting::Kind ':constants';
use Ledger::Transaction::State ':constants';

enum 'Ledger::Type::Posting::Kind', [REAL, VIRTUALBALANCED, VIRTUALUNBALANCED];

enum 'Ledger::Type::Transaction::State', [DEFAULT, CLEARED, PENDING];

enum 'Ledger::Type::ErrorLevel', [ qw(warning error) ];

subtype 'Ledger::Type::PostingAmount::Val',
    as 'Math::BigRat',
    message { "$_ is not a number!" };
    
coerce 'Ledger::Type::PostingAmount::Val',
    from 'Str',
    via { Math::BigRat->new($_) };

1;
