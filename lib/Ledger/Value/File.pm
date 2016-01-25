package Ledger::Value::File;
use Moose;
use namespace::sweep;

extends 'Ledger::Value';

with (
    'Ledger::Role::IsValue',
    );

has '+value' => (
    isa      => 'Path::Class::File',
    );

sub _compute_text {
    my $self = shift;

    return $self->value->stringify;
}

around 'value' => sub {
    my $orig = shift;
    my $self = shift;
    
    return $self->$orig()
	unless @_;
    
    my $file = shift;
    if (ref(\$file) eq "SCALAR") {
	# assuming a String we will try to convert
	$file = Path::Class::File->new($file);
    }
    return $self->$orig($file);
};

1;
