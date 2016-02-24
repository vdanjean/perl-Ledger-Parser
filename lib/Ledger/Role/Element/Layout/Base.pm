package Ledger::Role::Element::Layout::Base;
use Moose::Role;
use namespace::sweep;

BEGIN {
    if ($ENV{'TRACELOAD'}) {
	print "loading ", __PACKAGE__, "\n";
    }
}
if ($ENV{'TRACELOAD'}) {
    print "executing ", __PACKAGE__, "\n";
}

requires 'load_values_from_reader';

with (
    'Ledger::Role::HaveParent',
    'Ledger::Role::IsPrintable',
    'Ledger::Role::HaveCachedText' => {
	-excludes => [ 'as_string' ],
    },
    'Ledger::Role::HaveValues',
    'Ledger::Role::Element::Layout::Base',
    'Ledger::Role::Readable',
    );

sub compute_text {
    my $self = shift;
    return join('', 
		(
		 map {
		     my $name_str=$_.'_str';
		     $self->$name_str
		 } $self->get_all_value_names
		))."\n";
}

BEGIN {
    if ($ENV{'TRACELOAD'}) {
	print "loaded ", __PACKAGE__, "\n";
    }
}
if ($ENV{'TRACELOAD'}) {
    print "executed ", __PACKAGE__, "\n";
}

1;
