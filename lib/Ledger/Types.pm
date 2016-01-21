package Ledger::Types;
use Moose::Util::TypeConstraints;
use namespace::sweep;
use Ledger::Posting::Kind ':constants';
use Ledger::Transaction::State ':constants';
use Math::BigRat;

subtype 'Ledger::Type::Amount',
    as 'Math::BigRat',
    message { "$_ is not a number!" };
    
coerce 'Ledger::Type::Amount',
    from 'Str',
    via { Math::BigRat->new($_) };

enum 'Ledger::Type::Posting::Kind', [REAL, VIRTUALBALANCED, VIRTUALUNBALANCED];

enum 'Ledger::Type::Transaction::State', [DEFAULT, CLEARED, PENDING];

enum 'Ledger::Type::ErrorLevel', [ qw(warning error) ];

1;

