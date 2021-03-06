package Ledger::Util::ValueAttribute;
use Moose ();
use Moose::Exporter;
use Scalar::Util qw(blessed);
use Ledger::Role::HaveValues;
#use Moose::Util qw/find_meta does_role apply_all_roles/;;

Moose::Exporter->setup_import_methods(
    with_meta => [ 'has_value', 
		   'has_value_constant',
		   'has_value_directive',
		   'has_value_separator_optional',
		   'has_value_separator_simple',
		   'has_value_separator_hard',
		   'has_value_indented_line',
    ],
    #also      => 'Moose',
    );

use UNIVERSAL::require;
my $default_auto_order=1000;
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
	if (ref($attr{'default'}) eq 'CODE') {
	    $buildhash{'_default_code'}=$attr{'default'};
	} else {
	    $buildhash{'value'}=$attr{'default'};
	    $buildhash{'default_value'}=$attr{'default'};
	}
    }
    if (exists($attr{'format_type'})) {
	$buildhash{'format_type'}=$attr{'format_type'};
    }
    if (exists($attr{'order'})) {
	$buildhash{'order'}=$attr{'order'};
    } else {
	# ensure 'auto' order within a source file
	# nothing is done for composition
	$buildhash{'order'} = $default_auto_order;
	$default_auto_order += 10;
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

    if ($name !~ /^[+]/) {
	%attrhash=(
	    %attrhash,
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
	    lazy      => 1,
	    init_arg  => undef,
	    );
    }

    $meta->add_attribute(
	$name,
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
	%attrhash,
	);
    #$meta->find_method_by_name('_register_value_name')->execute($meta, $name);
}

sub has_value_constant {
    my ( $meta, $name, %attr ) = @_;

    if (!exists($attr{'default'})) {
	die "Missing 'default' attribute in constant value $name";
    }
    
    has_value($meta, $name,
	      isa      => 'Constant',
	      required  => 1,
	      reset_on_cleanup => 1,
	      %attr,
	);
}

sub has_value_directive {
    my ( $meta, $name, %attr ) = @_;
    
    has_value_constant($meta, 'directive',
		       default          => $name,
		       order            => -50,
		       %attr,
	);
}

sub has_value_separator_simple {
    my ( $meta, $name, %attr ) = @_;

    has_value($meta, $name,
	      isa              => 'WS1',
	      required         => 1,
	      reset_on_cleanup => 1,
	      default          => ' ',
	      %attr,
	);
}

sub has_value_separator_optional {
    my ( $meta, $name, %attr ) = @_;

    has_value($meta, $name,
	      isa              => 'WS0',
	      required         => 1,
	      reset_on_cleanup => 1,
	      default          => ' ',
	      %attr,
	);
}

sub has_value_separator_hard {
    my ( $meta, $name, %attr ) = @_;

    has_value($meta, $name,
	      isa              => 'WS0',
	      required         => 1,
	      reset_on_cleanup => 1,
	      default          => '  ',
	      %attr,
	);
}

sub has_value_indented_line {
    my ( $meta, $name, %attr ) = @_;

    has_value($meta, $name,
	      isa              => 'WS1',
	      required         => 1,
	      reset_on_cleanup => 1,
	      default          => '    ',
	      order            => -70,
	      %attr,
	);
}

1;
