package Ledger::Parser;
use Moose;
use namespace::sweep;
use utf8;
#use Carp;
use Path::Class::File;

has 'linenum' => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_set_linenum',
    default  => 0,
    );

sub _inc_linenum {
    my $self = shift;
    $self->_set_linenum($self->linenum + 1);
}

has 'eof' => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_set_eof',
    required => 1,
    default  => 0,
    );

has 'next_line' => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_set_next_line',
    clearer  => '_unset_next_line',
    predicate=> '_has_next_line',
    );

before 'next_line' => sub {
    my $self = shift;
    
    if ((not $self->_has_next_line) && (not $self->eof)) {
	my $fh=$self->_fh;
	my $line=<$fh>;
	if (defined($line)) {
	    $self->_inc_linenum;
	    $self->_set_next_line($line);
	} else {
	    $self->_set_eof(1);
	    $self->_fh->close();
	}
    }
};

sub pop_line {
    my $self = shift;
    my $line = $self->next_line;
    $self->_unset_next_line;
    return $line;
}

sub give_back_next_line {
    my $self = shift;
    my $line = shift;

    if ($self->_has_next_line || $self->eof) {
	$self->_error("No way to give back next line in parser");
    }
    $self->_set_next_line($line);

}    

has '_fh' => (
    is       => 'rw',
    isa      => 'FileHandle',
    );

has 'file' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    writer   => '_set_file',
    required => 1,
    #coerce   => 1,
    trigger  => sub {
	my ( $self, $filename, $old_filename ) = @_;
	if (defined($self->_fh)) {
	    $self->_fh->close();
	}
	open my $fh, "<", $filename
	    or $self->_error("can't open file '$filename': $!\n");
	binmode($fh, ":utf8");
	$self->_fh($fh);
    },
    );

sub error_prefix {
    my $self = shift;
    return $self->file.":".$self->linenum.": ";
}

sub _error {
    my $self= shift;
    my $msg = shift;

    die $self->meta->name.": ".$self->error_prefix.$msg;
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %hash;
    
    if ( @_ == 1 && ref $_[0] ) {
	%hash=(%{$_[0]});
    } else {
	%hash=(@_);
    }
    if (exists($hash{'file'})) {
	$hash{'file'} = Path::Class::File->new($hash{'file'});
    }
    return $class->$orig(%hash);
};

1;
# ABSTRACT: Parse Ledger journals
