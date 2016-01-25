package Ledger::Transaction;
use Moose;
use namespace::sweep;
use Ledger::Types;
use Ledger::Transaction::State;
use TryCatch;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Journal::Element';

with (
    'Ledger::Role::IsElementWithElements' => {
	-excludes => [ 'as_string', '_printable_elements' ],
    },
    );

has '+elements' => (
    isa      => 'ArrayRef[Ledger::Transaction::Element]',
    );

sub _setupElementKinds {
    return [
	'Ledger::Transaction::Note',
	'Ledger::Posting'
	];
}

has_value 'date' => (
    isa         => 'Date',
    required    => 1,
    );
    
has_value 'auxdate' => (
    isa         => 'Date',
    );

has_value 'ws1' => (
    isa              => 'WS1',
    required         => 1,
    reset_on_cleanup => 1,
    default          => ' ',
    );

has_value 'state' => (
    isa         => 'TransactionState',
    required    => 1,
    default     => Ledger::Transaction::State::DEFAULT,
    );

has_value 'ws2' => (
    isa              => 'WS0',
    required         => 1,
    reset_on_cleanup => 1,
    default          => ' ',
    );

has_value 'code' => (
    isa         => 'Str',
    );

has_value 'ws3' => (
    isa              => 'WS0',
    required         => 1,
    default          => ' ',
    );

has_value 'description' => (
    isa      => 'Str',
    required => 1,
    );

has_value 'ws4' => (
    isa              => 'WS2',
    required         => 1,
    reset_on_cleanup => 1,
    default          => '  ',
    );

has_value 'note' => (
    isa      => 'MetaData',
    );

before 'load_from_reader' => sub {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_re' => qr/^[0-9]/,
	'parse_line_re' => qr<
	    ^(?<date>[0-9]\S*)
	    (?: = (?<auxdate>[0-9]\S*))?
            (?<ws1>\s+)
	    (?: (?<state>[!*]) (?<ws2>\s*) )?
	    (?: \((?<code>[^\)]+)\) (?<ws3>\s*))?
	    (?<description>\S.*?)
	    (?: (?<ws4>\s{2,}|\t);(?<note>.*) )?
	                    >x,
	'accept_error_msg' => "invalid transaction line",
	'noaccept_error_msg' => "not starting an transaction block",
	'parse_value_error_msg' => "invalid data in transaction line",
	'store' => 'all',
	);
    return;
};

sub compute_text {
    my $self = shift;

    return $self->compute_text_from_values(
	$self->config->transaction_format."\n",
	);
}

sub _printable_elements {
    my $self = shift;
    return @_;
}

sub as_string {
    my $self = shift;
    return $self->_as_string_main
	.$self->_as_string_elements(
	$self->_filter_elements(
	    sub {
		not $_->isa('Ledger::Posting');
	    }
	))
	.$self->_as_string_elements(
	$self->_filter_elements(
	    sub {
		$_->isa('Ledger::Posting');
	    }
	));
}

override 'validate' => sub {
    my $self = shift;

    super();

    # some sanity checks for the transaction
    for my $kind (Ledger::Posting::Kind::REAL,
		  Ledger::Posting::Kind::VIRTUALBALANCED) {
      CHECK:
	{
	    my @postings=$self->_filter_elements(
		sub {
		    $_->isa('Ledger::Posting')
			&& $_->account->kind eq $kind;
		}
		);
	    my $num_postings = scalar(@postings);
	    last CHECK if !$num_postings;
	    if ($num_postings == 1 && !$postings[0]->has_amount) {
		#$self->_err("Posting amount cannot be null");
		# ledger allows this
		last CHECK;
	    }
	    my $num_nulls = 0;
	    my %bals; # key = commodity
	    for my $p (@postings) {
		if (!$p->amount->has_amount) {
		    $num_nulls++;
		    next;
		}
		$bals{$p->amount->commodity_str} += $p->amount->amount;
	    }
	    last CHECK if $num_nulls == 1;
	    if ($num_nulls) {
		$self->_err("Transaction:\n" . $self . 
			    "\nThere can only be one posting with null amount");
	    }
	    for (keys %bals) {
		$self->_err("Transaction not balanced:\n" . $self . "\n" .
                            (-$bals{$_}) . ($_ ? " $_":"")." needed in " .
			    $kind . " postings")
		    if $bals{$_} != 0;
	    }
	}
    }
};

use Carp;
sub _err {
    my ($self, $msg) = @_;
    croak join(
        "",
        #@{ $self->{_include_stack} } ? "$self->{_include_stack}[0] " : "",
        #"line $self->{_linum}: ",
        $msg#." in\n".$self->as_string
    );
}

1;
