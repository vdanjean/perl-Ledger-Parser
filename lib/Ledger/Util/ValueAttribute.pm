package Ledger::Util::ValueAttribute;
use Moose ();
use Moose::Exporter;
use Scalar::Util qw(blessed);
use Ledger::Role::HaveValues;
#use Moose::Util qw/find_meta does_role apply_all_roles/;;

Moose::Exporter->setup_import_methods(
    with_meta => [ 'has_value' ],
    #also      => 'Moose',
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
	'reset_on_cleanup' => $attr{'reset_on_cleanup'} // 0,
	);
    my %attrhash=();
    if (exists($attr{'default'})) {
	$buildhash{'value'}=$attr{'default'};
	$buildhash{'default_value'}=$attr{'default'};
    }
    if (exists($attr{'format_type'})) {
	$buildhash{'format_type'}=$attr{'format_type'};
    }

    my $role='Ledger::Role::HaveValues';
    if (! $meta->does_role($role)) {
	if ($meta->isa("Moose::Meta::Role")) {
	    die "missing \"with '$role';\" in ".$meta->name."\n";
	}
	#print "=> [".$meta->name."] Registering $role to $meta\n";
	$role->meta->apply($meta);
	#apply_all_roles($meta, $role);
	# meta has been modified/reinstanciated. We reload it
	$meta = ($meta->name)->meta;
	#my @roles=$meta->calculate_all_roles_with_inheritance;
	#print "roles=@roles\n";
	#print "   Current roles :\n     ".join(
	#    "\n     ",
	#    (map { $_->name }
	#     $meta->calculate_all_roles_with_inheritance))."\n";
	#print "=> [".$meta->name."] Registered $role to $meta\n";
	#$meta->add_role($role->meta);
	#$role='Ledger::Role::HaveParent';
    }
    #print "<= Registered $role to $meta ".$meta->name."\n";
    #print "   [".$meta->name."] Adding Value attribute $name ($meta)\n";

  TYPE:
    while(1) {
	foreach my $t ('Ledger::Value::'.$attrtype, $attrtype) {
	    if ($t->require) {
		$type=$t;
		last TYPE;
	    }
	    $t =~ s,::,/,g;
	    print $@ if $@ !~ /^Can't locate $t\.pm in /;
	}
	die "Unkwown Value type '".$attrtype.
	    "'. Is 'has_class' from ".$meta->name." using a correct 'isa'?\n";
    }

    $meta->add_attribute(
	$name,
	is        => 'bare',
	isa       => $type,
	handles   => { 
	    $name             => 'value',
	    'has_'.$name      => 'present',
	    'clear_'.$name    => 'reset',
	    $name.'_str'      => 'value_str',
	    $name.'_validate' => 'validate',
	},
	reader    => '_'.$name.'_rawvalue',
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
	%attrhash,
	);
    #$meta->find_method_by_name('_register_value_name')->execute($meta, $name);
}

1;
