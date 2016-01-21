package Ledger::Util::ValueAttribute;
use Moose ();
use Moose::Exporter;
use Scalar::Util qw(blessed);
use Ledger::Role::HaveValues;

Moose::Exporter->setup_import_methods(
    with_meta => [ 'has_value' ],
    also      => 'Moose',
    );

use UNIVERSAL::require;
sub has_value {
    #print "'", join("', '",@_), "'\n";
    my ( $meta, $name, %attr ) = @_;
#    my $meta = shift;
#    my $name = shift;
#    my %attr = (@_);
    my $attrtype = $attr{'isa'} // 'Str';
    my $type;
    my %buildhash=(
	'required' => $attr{'required'} // 0,
	);
    my %attrhash=();
    if (exists($attr{'default'})) {
	$buildhash{'value'}=$attr{'default'};
	$buildhash{'default_value'}=$attr{'default'};
    }

    my $role='Ledger::Role::HaveValues';
    if (! $meta->does_role($role)) {
	print "Registering $role\n";
	#$role->meta->apply($meta);
	#$meta->add_role($role->meta);
	#$role='Ledger::Role::HaveParent';
    }

  TYPE:
    while(1) {
	foreach my $t ('Ledger::Value::'.$attrtype, $attrtype) {
	    if ($t->require) {
		$type=$t;
		last TYPE;
	    }
	    print $@ if $@ !~ /^Can't locate /;
	}
	die "Unkwown value type '".$attrtype."'";
    }
	    
    $meta->add_attribute(
	$name,
	is        => 'bare',
	isa       => $type,
	handles   => { 
	    $name             => 'value',
	    'has_'.$name      => 'present',
	    'clear_'.$name    => 'reset',
	    $name.'_str'      => 'as_string',
	    $name.'_validate' => 'validate',
	},
	required  => 1,
	default   => sub {
	    my $self=shift;
	    #print 'creating '.$name.' with parent: ', blessed($self), "\n";
	    #print 'attr names: '.join(", ", $self->all_value_names)."\n";
	    my $attr=$type->builder(
		'parent' => $self,
		'name' => $name,
		%buildhash,
		);
	    $self->_register_value($name, $attr);
	    return $attr;
	},
	lazy      => 1,
	init_arg  => undef,
	);
    #print "Methode: ",$meta->find_method_by_name('_register_value_name'), "\n";
    $meta->find_method_by_name('_register_value_name')->execute($meta, $name);
}

1;
