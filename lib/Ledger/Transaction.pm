package Ledger::Transaction;
use Moose;
use namespace::sweep;
use Math::Decimal qw(dec_add);
use Ledger::Types;
use Ledger::Transaction::State;
use Time::Piece;
use Time::Moment;

with (
    'Ledger::Role::HaveCachedText' => {
	-alias => { as_string => '_as_string_main' },
	-excludes => 'as_string',
    },
    'Ledger::Role::ReadableFromParser',
    'Ledger::Role::HaveMetadata',
    'Ledger::Role::HaveParsableElementsList' => { -excludes => 'BUILD', },
    'Ledger::Role::HaveElements' => {
	-alias => { as_string => '_as_string_elements' },
	-excludes => [ 'as_string', '_printable_elements' ],
    },
    );

extends 'Ledger::Journal::Element';

has '+elements' => (
    isa      => 'ArrayRef[Ledger::Transaction::Element]',
    );

# TODO: value should come from config
sub input_date_format {
    my $self = shift;
    return '%Y-%m-%d';
}
sub date_format {
    my $self = shift;
    return '%Y-%m-%d';
}

sub year {
    my $self = shift;
    return (localtime)[5] + 1900;
}

has 'date' => (
    is       => 'rw',
    isa      => 'Time::Piece',
    trigger  => \&_clear_cached_text,
    clearer   => 'clear_date',
    predicate => 'has_date',
    required  => 1,
    );

has 'auxdate' => (
    is       => 'rw',
    isa      => 'Time::Piece',
    trigger  => \&_clear_cached_text,
    clearer   => 'clear_auxdate',
    predicate => 'has_auxdate',
    );

for my $d ('date', 'auxdate') {
    around $d => sub {
	my $orig = shift;
	my $self = shift;
	
	return $self->$orig()
	    unless @_;
	
	my $date = shift;
	if (ref(\$date) eq "SCALAR") {
	    # assuming a String we will try to convert
	    my $res=$self->_parse_date($date);
	    return $self->$orig($res->[1]);
	}
	return $self->$orig($date);
    };
}

has 'state' => (
    is       => 'rw',
    isa      => 'Ledger::Type::Transaction::State',
    default  => Ledger::Transaction::State::DEFAULT,
    predicate => 'has_state',
    );

around 'state' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig()
	unless @_;

    my $state = shift;
    $state =~ s/\s//g;
    if (Ledger::Transaction::State->isSymbol($state)) {
	$state=Ledger::Transaction::State->fromSymbol($state);
    }
    return $self->$orig($state);
};

sub clear_state {
    my $self = shift;
    $self->state(Ledger::Transaction::State::DEFAULT);
}

has 'code' => (
    is       => 'rw',
    isa      => 'Str',
    trigger  => \&_clear_cached_text,
    clearer   => 'clear_code',
    predicate => 'has_code',
    );

has 'description' => (
    is       => 'rw',
    isa      => 'Str',
    trigger  => \&_clear_cached_text,
    clearer   => 'clear_description',
    predicate => 'has_description',
    required => 1,
    );

has 'note' => (
    is       => 'rw',
    isa      => 'Str',
    trigger  => \&_clear_cached_text,
    clearer   => 'clear_note',
    predicate => 'has_note',
    );

around 'note' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig()
	unless @_;

    my $msg = shift;
    $msg =~ s/\s*$//;
    return $self->$orig($msg);
};


# note: $RE_xxx is capturing, $re_xxx is non-capturing
our $re_date = qr!(?:\d{4}[/-])?\d{1,2}[/-]\d{1,2}!;
our $RE_date = qr!(?:(\d{4})[/-])?(\d{1,2})[/-](\d{1,2})!;




sub _parsingEnd {
    my $self = shift;
    my $parser = shift;
    my $line = $parser->next_line;

    return ($line !~ /\S/ || $line =~ /^\S/);
}

sub _doElementKindsRegistration {
    my $self = shift;
    #print "registering\n";
    $self->_registerElementKind(
	'Ledger::Transaction::Note',
	'Ledger::Posting'
	);
};

sub _parse_date {
    my ($self, $str) = @_;
    return [400,"Invalid date syntax '$str'"] unless $str =~ /\A(?:$RE_date)\z/;

    my $tm;
    eval {
	# Argh : Time::Moment is doing a better validation
	# but Time::Piece allow any format (as --input-date-format in ledger)
	if (1) {
	    if ($self->input_date_format eq 'YYYY/DD/MM') {
		$tm = Time::Moment->new(
		    day => $2,
		    month => $3,
		    year => $1 || $self->year,
		    );
	    } else {
		$tm = Time::Moment->new(
		    day => $3,
		    month => $2,
		    year => $1 || $self->year,
		    );
	    }
	    $tm = Time::Piece->strptime(
		$tm->strftime($self->input_date_format),
		$self->input_date_format
		);
	} else {
	    $str =~ s,/,-,g;
	    $tm = Time::Piece->strptime($str, $self->input_date_format);
	}
    };
    if ($@) { return [400, "Invalid date '$str' for ".$self->input_date_format.": $@"] }
    [200, $tm];
}

sub new_from_parser {
    my $class = shift;
    my %attr = @_;
    my $parser = $attr{'parser'};
    
    my $line = $parser->next_line;
    if ($line =~ /^\d/) {
	return $class->new(@_);
    }
    
    return undef;
}

before 'load_from_parser' => sub {
    my $self = shift;
    my $parser = shift;

    my $line = $parser->pop_line;
    if ($line !~ m
	<^($re_date)                    # 1) actual date
	(?: = ($re_date))? (\s+)        # 2) effective date 3) ws
	(?: ([!*]) (\s*) )?             # 4) state 5) ws
	(?: \(([^\)]+)\) (\s*))?        # 6) code 7) ws
	(\S.*?)                         # 8) desc
	(?: (\s{2,}) ;(\S.+?) )?        # 9) ws 10) note
	(\R?)\z                         # 11) nl
	>x) {
	$parser->give_back_next_line($line);
	die $parser->error_prefix."Invalid transaction line syntax\n";
    }
    my $parsed_date=$self->_parse_date($1);
    if ($parsed_date->[0] != 200) {
	$self->_err($parsed_date->[1]);
    }
    $self->date($parsed_date->[1]);

    if (defined($2)) {
	$parsed_date=$self->_parse_date($2);
	if ($parsed_date->[0] != 200) {
	    $self->_err($parsed_date->[1]);
	}
	$self->auxdate($parsed_date->[1]);
    }

    $self->state($4) if defined($4);
    $self->code($6) if defined($6);
    $self->description($8);
    $self->note($10) if defined($10);
    $self->_cached_text($line);
};

sub compute_text {
    my $self = shift;
        my $transactionFormat =
	'@{date:%s}@{auxdate:=%s:%s} @{state:%s }@{code:%s :%s}'.
	'@{description:%s}@{note:  %s:%s}';
    my @formatParams=();

    push @formatParams, Ledger::Util->buildFormatParam(
	'date',
	'object' => $self,
	'value' => $self->date->strftime($self->date_format),
	);
    push @formatParams, Ledger::Util->buildFormatParam(
	'auxdate',
	'object' => $self,
	'value' => ($self->auxdate // localtime)->strftime($self->date_format),
	);
    push @formatParams, Ledger::Util->buildFormatParam(
	'state',
	'object' => $self,
	'value' => Ledger::Transaction::State->toSymbol(
	    $self->state
	),
	);
    push @formatParams, Ledger::Util->buildFormatParam(
	'code',
	'object' => $self,
	);
    push @formatParams, Ledger::Util->buildFormatParam(
	'description',
	'object' => $self,
	);
    push @formatParams, Ledger::Util->buildFormatParam(
	'note',
	'object' => $self,
	'value' => ";".($self->note // ""),
	);

    my $str=Ledger::Util->format(
	$transactionFormat => {@formatParams}
	);
    if ($str->[0] != 200) {
	$self->_err($str->[1]);
    }
    $str->[1] =~ s/\s+$//;
    return $str->[1]."\n";
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
  CHECK:
    {
	my @postings=$self->_filter_elements(
	    sub {
		$_->isa('Ledger::Posting');
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
            if (!$p->has_amount) {
                $num_nulls++;
                next;
            }
            if (defined($bals{$p->commodity})) {
		$bals{$p->commodity} = dec_add($bals{$p->commodity},
					       $p->amount);
	    } else {
		$bals{$p->commodity} = $p->amount;
	    }
        }
        last CHECK if $num_nulls == 1;
        if ($num_nulls) {
            $self->_err("There can only be one posting with null amount");
        }
        for (keys %bals) {
            $self->_err("Transaction not balanced, " .
                            (-$bals{$_}) . ($_ ? " $_":"")." needed")
                if $bals{$_} != 0;
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
        $msg." in\n".$self->as_string
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
    if (exists($hash{'parser'})) {
	# date and description will be parsed with the parser
	# setting fake values for now
        $hash{'date'} = localtime;
	$hash{'description'}='';
    }
    return $class->$orig(%hash);
};

1;
