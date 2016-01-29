package Ledger::Role::Readable;
use Moose::Role;
use namespace::sweep;
use TryCatch;
use Ledger::Util qw(indent);

requires 'load_from_reader';

sub BUILD {}

after 'BUILD' => sub {
    my $self = shift;
    my $args = shift;

    if (exists($args->{'reader'})) {
	$self->load_from_reader($args->{'reader'});
    }
};

sub load_from_reader_helper {
    my $self = shift;
    my %options = ( @_ );
    my $reader = $options{'reader'} // die "Missing reader parameter";

    my $line = $reader->pop_line;
    my $accept_re;
    if (defined($options{'accept_re'})) {
	$accept_re = $options{'accept_re'};
    } elsif (defined($options{'accept_line_re'})) {
	$accept_re = $options{'accept_line_re'};
	$accept_re = qr/$accept_re(?:\R?)\z/;
    } elsif (defined($options{'accept_with_blank_re'})) {
	$accept_re = $options{'accept_with_blank_re'};
	$accept_re = qr/$accept_re(?:\s|(?:\R?\z))/;
    }
    if(defined($accept_re)) {
	if ($line !~ /$accept_re/) {
	    # soft error, we give back the line
	    $reader->give_back_next_line($line);
	    die Ledger::Exception::ParseError->new(
		'line' => $line,
		'parser_prefix' => $reader->error_prefix,
		'message' => (
		    $options{'noaccept_error_msg'}
		    // ("not a ".$self->meta->name." line")),
		);
	}
    }
    my $parse_re;
    if (defined($options{'parse_re'})) {
	$parse_re = $options{'parse_re'};
    } elsif (defined($options{'parse_line_re'})) {
	$parse_re = $options{'parse_line_re'};
	$parse_re = qr/$parse_re\s*(?<NL>\R?)\z/;
    }
    my @error_msgs=();
    if ($line =~ /$parse_re/) {
	my %res=(%+);
	if (defined($options{'store'})) {
	    my $vnames;
	    if (ref(\$options{'store'}) eq "SCALAR" ) {
		if ($options{'store'} eq "all") {
		    $vnames = $self->_get_all_value_names;
		} else {
		    die "Invalid value for parameter 'store'";
		}
	    } elsif (ref($options{'store'}) eq "ARRAY" ) {
		$vnames=$options{'store'};
	    } else {
		die "Invalid parameter 'store'";
	    }
	    my $e;
	    foreach my $opt (@{$vnames}) {
		try {
		    my $opt_str=$opt.'_str';
		    $self->$opt_str($res{$opt}) if defined($res{$opt});
		} catch (Ledger::Exception::ValueParseError $e) {
		    push @error_msgs, $opt, $e->message;
		}
	    }
	}
	# after as any call to XXX_str(...) reset the cached text
	if ($options{'cache_line'} // 1) {
	    $self->_cached_text($line);
	}

	if (scalar(@error_msgs) == 0) {
	    return \%res;
	}
    }
    # A parsing error occurs
    my %attr=(
	'line' => $line,
	'parser_prefix' => $reader->error_prefix,
	);
    my $msg;
    if (scalar(@error_msgs)) {
	# we accepted the line (possibly twice), it is an hard error
	$attr{'abortParsing'} = 1;
	$msg = (
	    $options{'parse_value_error_msg'}
	    // ("in ".$self->meta->name.
		" while parsing the following value(s):"))."\n";
	my %errs = ( @error_msgs );
	my @vname=keys(%errs);
	$msg .= join("\n", (
			 map {
			     "{".$_."}: ".indent('  ', $errs{$_});
			 } @vname
		     ));
    } elsif(defined($accept_re)) {
	# we accepted the line, it is an hard error
	$attr{'abortParsing'} = 1;
	$msg = (
	    $options{'accept_error_msg'}
	    // ("invalid line (but recognised as a ".
		$self->meta->name.")"));
    } else {
	# it can be a soft error (not the good parser called)
	$reader->give_back_next_line($line);
	$msg = (
	    $options{'noaccept_error_msg'}
	    // ("invalid ".$self->meta->name." line"));
    }
    die Ledger::Exception::ParseError->new(%attr, 'message' => $msg);
}
    

1;

