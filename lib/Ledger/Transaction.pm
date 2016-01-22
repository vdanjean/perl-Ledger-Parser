package Ledger::Transaction;
use Moose;
use namespace::sweep;
use Ledger::Types;
use Ledger::Transaction::State;
use TryCatch;
use Ledger::Util::ValueAttribute;

extends 'Ledger::Journal::Element';

with (
    'Ledger::Role::HaveCachedText' => {
	-alias => { as_string => '_as_string_main' },
	-excludes => 'as_string',
    },
    'Ledger::Role::Readable',
    'Ledger::Role::HaveMetadata',
    'Ledger::Role::HaveReadableElementsList' => { -excludes => 'BUILD', },
    'Ledger::Role::HaveElements' => {
	-alias => { as_string => '_as_string_elements' },
	-excludes => [ 'as_string', '_printable_elements' ],
    },
    'Ledger::Role::HaveValues',
    );

has '+elements' => (
    isa      => 'ArrayRef[Ledger::Transaction::Element]',
    );

sub _setupElementKinds {
    return [
	'Ledger::Transaction::Tag',
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

has_value 'state' => (
    isa         => 'TransactionState',
    required    => 1,
    default     => Ledger::Transaction::State::DEFAULT,
    );

has_value 'code' => (
    isa         => 'Str',
    );

has_value 'description' => (
    isa      => 'Str',
    required => 1,
    );

has_value 'note' => (
    isa      => 'EndStrippedStr',
    );

sub _readEnded {
    my $self = shift;
    my $reader = shift;
    my $line = $reader->next_line;

    return ($line !~ /\S/ || $line =~ /^\S/);
}

before 'load_from_reader' => sub {
    my $self = shift;
    my $reader = shift;

    my $line = $reader->pop_line;
    if ($line !~ m
	<^([0-9]\S*)                    # 1) actual date
	(?: = ([0-9]\S*))? (\s+)        # 2) effective date 3) ws
	(?: ([!*]) (\s*) )?             # 4) state 5) ws
	(?: \(([^\)]+)\) (\s*))?        # 6) code 7) ws
	(\S.*?)                         # 8) desc
	(?: (\s{2,} ;\s?)(.*) )?        # 9) ws 10) note
	(\R?)\z                         # 11) nl
	>x) {
	$reader->give_back_next_line($line);
	die Ledger::Exception::ParseError->new(
	    'line' => $line,
	    'parser_prefix' => $reader->error_prefix,
	    'message' => "not an initial transaction line",
	    );
    }
    my $e;
    try {
	$self->date_str($1);
	$self->auxdate_str($2) if defined($2);
	$self->state_str($4) if defined($4);
	$self->code_str($6) if defined($6);
	$self->description_str($8);
	$self->note_str($10) if defined($10);
	$self->_cached_text($line);
    }
    catch (Ledger::Exception::ValueParseError $e) {
	my $msg=$e->message;
	$reader->give_back_next_line($line);
	die Ledger::Exception::ParseError->new(
	    'line' => $line,
	    'parser_prefix' => $reader->error_prefix,
	    'message' => "while reading transaction: $msg",
	    'abortParsing' => 1,
	    );
    }
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

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %hash;

    if ( @_ == 1 && ref $_[0] ) {
        %hash=(%{$_[0]});
    } else {
        %hash=(@_);
    }
    if (exists($hash{'reader'})) {
	# date and description will be set with the reader informations
	# setting fake values for now
	$hash{'description'}='';
    }
    return $class->$orig(%hash);
};

1;
