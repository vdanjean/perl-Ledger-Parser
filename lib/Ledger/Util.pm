package Ledger::Util;
use strict;
use warnings;
use List::Util qw(min);
use Scalar::Util qw(blessed);
use Math::BigRat;
use utf8;
use Carp;

my $re_account_part = qr/(?:
                              [^\s:\[\(;]+?[ ]??[^\s:\[\(;]*?
                          )+?/x; # don't allow double whitespace nor tabulation
my $re_account = qr/$re_account_part(?::$re_account_part)*/;
sub re_account {
    return $re_account;
}

my $re_commodity = qr/[A-Z_]+[A-Za-z_]*|[\$£€¥]/;
sub re_commodity {
    return $re_commodity;
}

sub format {
    my $class = shift;
    my $format = shift;
    my $args = shift;
    my @values=();

    while($format =~ /(^|[^@])@\{([^:]+):([^}]+)\}/) {
	my $name=$2;
	my @subformats=split(':',$3);
	if (not exists($args->{$name})) {
	    return [400, "Invalid variable '$name' in format string '$format'" ];
	}
	my $avail_values=$args->{$name};
	my $nb=min(scalar(@subformats), scalar(@{$avail_values}))-1;
	#print "nb=$nb for $name (", scalar(@subformats), "/",
	#scalar(@{$avail_values}), ")\n";
	for (;$nb>=0; $nb--) {
	    if ($subformats[$nb] ne "" && defined($avail_values->[$nb])) {
		push @values, $avail_values->[$nb];
		my $f=$subformats[$nb];
		my $param=scalar(@values).'$';
		$f =~ s/%/%$param/;
		$format =~ s/(^|[^@])@\{([^:]+):([^}]+)\}/$1$f/;
		last;
	    }
	}
	if ($nb < 0) {
	    return [400, "No format for '$name' to apply in format string '$format'" ];
	}
    }
    return [200, sprintf($format, @values)];
}

sub buildFormatParam {
    my $class = shift;
    my $name = shift,
    my %info = @_;

    my $type='string';
    $type=$info{'type'} if exists($info{'type'});

    my $obj=undef;
    $obj=$info{'object'} if exists($info{'object'});
    
    my $attr=$name;
    $attr=info{'attribute'} if exists($info{'attribute'});
    
    my $pred='has_'.$attr;
    $pred=$info{'predicate'} if exists($info{'predicate'});
    
    my $value;
    if (exists($info{'value'})) {
	$value=$info{'value'};
    } else {
	$value=$obj->$attr;
    }
    my $has_value=1;
    if (exists($info{'has_value'})) {
	$has_value=$info{'has_value'};
    } elsif (defined($obj)) {
	$has_value=$obj->$pred;
    }

    my @fpar=();
    if ($has_value) {
	#print "pushing value '$value' for $name\n";
	push @fpar, $value;
	if ($type eq 'Num') {
	    if (Math::BigRat->new($value)->is_int) {
		push @fpar, undef, $value;
	    }
	} elsif ($value eq '') {
	    push @fpar, "";
	}
    } else {
	push @fpar, "", "";
    }
    return $name, \@fpar;
}

sub indent {
    my $start = shift;
    my $str = shift;
    $str =~ s/\n/\n$start/m;
    return $str;
}

sub run {
    my $code = shift;
    my $obj = shift;
    my @params = @_;
    if (ref($code) eq "CODE") {
	# code
	return $code->($obj, @params);
    } elsif (blessed($obj) && $obj->can($code)) {
	# method name
	return $obj->$code(@params);
    } else {
	croak "Invalid code $code";
    }    
}

sub runs {
    my $codes = shift;
    my @params = @_;
    if (ref($codes) ne "ARRAY") {
	$codes=[$codes];
    }
    foreach my $code (@{$codes}) {
	run($code, @params);
    }
}

our (@ISA, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    @EXPORT_OK = qw(format buildFormatParam re_account re_commodity indent run runs);
    %EXPORT_TAGS = (
	'regexp' => ['re_account', 're_commodity'],
	'all' => \@EXPORT_OK,
	);
}

1;
