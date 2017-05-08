package Ledger::Transaction;
use Moose;
use namespace::sweep;
use Ledger::Types;
use Ledger::Transaction::State;
use TryCatch;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Journal::Element';

with (
    'Ledger::Role::Element::Layout::MultiLines::List',
    'Ledger::Role::HaveSubElementNotes',
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

has_value_separator_simple 'ws1';

has_value 'state' => (
    isa         => 'TransactionState',
    required    => 1,
    default     => Ledger::Transaction::State::DEFAULT,
    );

has_value_separator_optional 'ws2';

has_value 'code' => (
    isa         => 'Str',
    );

has_value_separator_optional 'ws3' => (
    reset_on_cleanup => 0,
    );

has_value 'description' => (
    isa      => 'Str',
    required => 1,
    );

has_value_separator_hard 'ws4';

has_value_separator_optional 'ws5';

has_value 'note' => (
    isa      => 'MetaData',
    );

sub load_values_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_re' => qr/^[0-9]/,
	'parse_line_re' => qr<
	    ^(?<date>[0-9]\S*?)
	    (?: = (?<auxdate>[0-9]\S*?))?
            (?<ws1>\s+)
	    (?: (?<state>[!*]) (?<ws2>\s*) )?
	    (?: \((?<code>[^\)]+)\) (?<ws3>\s*))?
	    (?<description>\S.*?)
	    (?: (?<ws4>\s{2,}|\t);(?<ws5>\s*)(?<note>.*) )?
	                    >x,
	'accept_error_msg' => "invalid transaction line",
	'noaccept_error_msg' => "not starting an transaction block",
	'parse_value_error_msg' => "invalid data in transaction line",
	'store' => 'all',
	);
    return;
}

sub compute_text {
    my $self = shift;

    return $self->compute_text_from_values(
	$self->config->transaction_format."\n",
	);
}

sub _printable_elements {
    my $self = shift;
    use sort 'stable';
    return sort {
	$a->isa('Ledger::Posting') <=> $b->isa('Ledger::Posting')
    } ($self->all_elements(@_));
}

override 'validate' => sub {
    my $self = shift;

    #print "V1 in ",ref($self),"\n";
    super();
    #print "V2\n";

    # some sanity checks for the transaction
    for my $kind (Ledger::Posting::Kind::REAL,
		  Ledger::Posting::Kind::VIRTUALBALANCED) {
      CHECK:
	{
	    #print "V2 a\n";
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
    #print "V3\n";
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

use utf8;
sub addPosting {
    my $self=shift;
    my %args=(@_);

    my $hp={
	'account' => {
	    'name' => $args{'account'} // 'Missing::Account::Name',
	    'kind' => $args{'accountKind'} // 'Real',
	},
	'amount' => {
	    # TODO: FIXME: useless string convertion
	    'amount' => ($args{'amount'} // 0)."",
	    'commodity' => $args{'commodity'} // '€',
	},
    };
    return $self->add('Posting', $hp);
}

###################################################################
# TAG management
with (
    'Ledger::Role::Element::AppliedTags',
    );

sub _collect_tags {
    my $self = shift;

    my $val_it = $self->valuesIterator(
	'filter-out-element' => sub {
	    return shift->isa('Ledger::Posting');
	},
	'select-value' => sub {
	    my $obj = shift;
	    return $obj->isa("Ledger::Value::MetaData")
		&& $obj->value->does("Ledger::Role::HaveTags");
	}
	);
    $self->_reset_tags;
    while (my $tag = $val_it->next) {
	$self->_merge_tags($tag->value);
    }
}
    
1;
