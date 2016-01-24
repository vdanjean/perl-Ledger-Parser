package Ledger::Value::SubType::MetaDataBase;
use Moose;
use namespace::sweep;

sub BUILD {
    my $self = shift;
    if ($self->meta->name eq __PACKAGE__) {    
	die "This virtual class must not be instanciated\n";
    }
};

1;
