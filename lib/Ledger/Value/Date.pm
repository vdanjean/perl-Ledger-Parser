package Ledger::Value::Date;
use Moose;
use namespace::sweep;
use TryCatch;
use Time::Piece;
use Time::Moment;

extends 'Ledger::Value';

with (
    'Ledger::Role::IsValue',
    );

has '+raw_value' => (
    isa      => 'Time::Piece',
    );

# note: $RE_xxx is capturing, $re_xxx is non-capturing
our $re_date = qr!(?:\d{4}[/-])?\d{1,2}[/-]\d{1,2}!;
our $RE_date = qr!(?:(\d{4})[/-])?(\d{1,2})[/-](\d{1,2})!;

sub _parse_date {
    my ($self, $str) = @_;
    my ($n1, $n2, $n3);

    print "Role : ", $self->meta->does_role('Ledger::Role::HaveParent'), "\n";
    print "meth : ", $self->can('parent'), "\n";

    
    if ($self->config->input_date_format eq 'YYYY/DD/MM'
	|| $self->config->input_date_format eq 'YYYY/MM/DD') {
	$self->die_bad_string(
	    $str,
	    'invalid date syntax for '.
	    $self->config->input_date_format.' format')
	    unless $str =~ /\A(?:$RE_date)\z/;
	$n1=$1;
	$n2=$2;
	$n3=$3;
    }

    my $tm;
    try {
	    
	# Argh : Time::Moment is doing a better validation
	# but Time::Piece allow any format (as --input-date-format in ledger)
	if ($self->config->input_date_format eq 'YYYY/DD/MM'
	    || $self->config->input_date_format eq 'YYYY/MM/DD') {
	    if ($self->config->input_date_format eq 'YYYY/DD/MM') {
		$tm = Time::Moment->new(
		    day => $n2,
		    month => $n3,
		    year => $n1 || $self->config->year,
		    );
	    } elsif ($self->config->input_date_format eq 'YYYY/MM/DD') {
		$tm = Time::Moment->new(
		    day => $n3,
		    month => $n2,
		    year => $n1 || $self->config->year,
		    );
	    }
	    $tm = Time::Piece->strptime(
		$tm->strftime($self->config->date_format),
		$self->config->date_format
		);
	} else {
	    $str =~ s,/,-,g;
	    $tm = Time::Piece->strptime($str, $self->config->input_date_format);
	}
    }
    catch {
	die_bad_string(
	    $str,
	    'invalid date syntax for '.
	    $self->config->input_date_format.' format');
    }
    return $tm;
}

sub compute_text {
    my $self = shift;

    return $self->raw_value->strftime($self->config->date_format);
}

around 'value' => sub {
    my $orig = shift;
    my $self = shift;
    
    return $self->$orig()
	unless @_;
    
    my $date = shift;
    if (ref(\$date) eq "SCALAR") {
	# assuming a String we will try to convert
	my $res=$self->_parse_date($date);
	my $r = $self->$orig($res);
	$self->_cached_text($date);
	return $r;
    }
    return $self->$orig($date);
};

1;
