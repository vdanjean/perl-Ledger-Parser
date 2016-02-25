package Ledger::Role::HaveSubValues;
use Moose::Role;
use namespace::sweep;

with (
    'Ledger::Role::Iterator::Values',
    );

requires '_null_value';

has '_has_value' => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 0,
    lazy     => 1,
    required => 1,
    );

around '_compute_text' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->value->compute_text;
};

around 'present' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->_has_value;    
};

around '_reset' => sub {
    my $orig = shift;
    my $self = shift;

    $self->value($self->_null_value);
    $self->_has_value(0);
};

around 'value' => sub {
    my $orig = shift;
    my $self = shift;
    
    return $self->$orig()
	unless @_;
    
    my $val = shift;
    if (ref(\$val) eq "SCALAR") {
	# assuming a String we will try to convert
	$self->_parse_str($val);
	$self->_has_value(1);
	return ;
    }
    $self->_has_value(1);
    return $self->$orig($val);
};

before 'cleanup' => sub {
    my $self = shift;
    $self->value->cleanup(@_);
};

sub _parse_str {
    my $self = shift;

    return $self->value->parse_str(@_);
}

sub _iterable_values {
    my $self = shift;
    return $self->value->_iterable_values(@_);
}

1;
