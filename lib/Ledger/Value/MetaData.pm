package Ledger::Value::MetaData;
use Moose;
use namespace::sweep;
use Ledger::Exception::ValueParseError;
use TryCatch;

my @metadatatypes;
BEGIN {
    @metadatatypes=qw(TaggedValue PlainNote);# SimpleTags PlainNote);

    for my $type (@metadatatypes) {
	my $mod="Ledger::Value::SubType::$type";
	$mod->use or die $@;
    }
}

extends 'Ledger::Value';

with (
    'Ledger::Role::IsValue',
    );

has '+value' => (
    isa      => 'Ledger::Value::SubType::MetaDataBase',
    required => 1,
    builder  => '_null_value',
    );

# after because we define the 'value' method with 'around'
with (
    'Ledger::Role::HaveSubValues',
    );

sub _null_value {
    my $self = shift;
    Ledger::Value::SubType::PlainNote->new(
	'parent' => $self,
	);
}

sub _parse_str {
    my ($self, $str) = @_;

    my $e;
    my @msgs=();

    for my $type (@metadatatypes) {
	#print "Trying $type\n";
	my $metadata;
	try {
	    my $realtype="Ledger::Value::SubType::$type";
	    $metadata = $realtype->new(
		parent => $self,
		);
	    my $res = $metadata->parse_str($str);
	    $self->value($metadata);
	    #print "yes\n";
	    return $res;
	}
	catch (Ledger::Exception::ValueParseError $e) {
	    #print "Catching error for $type ($str)\n";
	    push @msgs, $e->message;
	}
    }
    #print "Dying\n";
    die Ledger::Exception::ValueParseError->new(
        'message' => "Unable to read metadata:\n    * ".join("\n    * ", @msgs),
        );
}

## BEGIN Hash support
around '_hashKey' => sub {
    my $orig = shift;
    my $self = shift;
    my $realclass = $self->value->meta->name;
    if ($realclass !~ /^Ledger::Value::SubType::([^:]+)/) {
	die "Invalid subclass '$realclass' for MetaData value";
    }
    $realclass=$1;
    return $self->$orig(@_).".".$realclass;
};
## END Hash support

1;
