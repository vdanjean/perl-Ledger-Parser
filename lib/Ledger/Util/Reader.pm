package Ledger::Util::Reader;
use Moose;
use namespace::sweep;
use utf8;
#use Carp;
use Path::Class::File;

my $DEBUG = 0;
sub debug {
    print $_[0], "\n";
}

has 'lineno' => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_set_lineno',
    predicate => 'has_lineno',
    );

has 'filename' => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_set_filename',
    predicate => 'has_filename',
    );

has 'parent' => (
    is       => 'ro',
    isa      => 'Ledger::Util::Reader',
    writer   => '_set_parent',
    predicate => 'has_parent',
    clearer  => '_unset_parent',
    );

has 'cwd' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    writer   => '_set_cwd',
    );

has 'file' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    predicate=> 'is_file',
    writer   => '_set_file',
    init_arg => undef,
    );

sub id {
    my $self=shift;

    return undef if not $self->has_filename;
    if ($self->has_lineno) {
	return $self->filename.':'.$self->lineno.':';
    } else {
	return $self->filename.':';
    }
}

sub parent_with_id {
    my $self=shift;

    my $parent=$self->parent;
    while(defined($parent) && not defined($parent->id)) {
	$parent=$parent->parent;
    }
    return $parent;
}

sub error_prefix {
    my $self = shift;
    my $id_reader=$self;
    my $suffix="";
    while (defined($id_reader) and not defined($id_reader->id)) {
	$id_reader=$id_reader->parent;
    }
    if (not defined($id_reader)) {
	return "<>: ";
    } else {
	$suffix = $id_reader->id.' ';
    }
    my $parent=$self->parent_with_id;
    return $suffix if not defined($parent);

    my $prefix="In file included from ".$parent->id."\n";
    $parent=$parent->parent_with_id;
    while (defined($parent)) {
	$prefix .= '                 from '.$parent->id."\n";
	$parent=$parent->parent_with_id;
    }
    return $prefix.$suffix;
}

sub _inc_lineno {
    my $self = shift;
    $self->_set_lineno($self->lineno + 1);
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
    
    debug "next_line called" if $DEBUG;
    if ((not $self->_has_next_line) && (not $self->eof)) {
	debug "next_line computed" if $DEBUG;
	my $fh=$self->_fh;
	my $line=<$fh>;
	if (defined($line)) {
	    $self->_inc_lineno;
	    $self->_set_next_line($line);
	    debug "next_line: loaded $line" if $DEBUG;
	} else {
	    $self->_set_eof(1);
	    $self->_fh->close();
	    debug "next_line: EOF" if $DEBUG;
	}
    }
};

has '_fh' => (
    is       => 'rw',
    isa      => 'FileHandle',
    );

has 'type' => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_type',
    );

sub pop_line {
    my $self = shift;
    my $line = $self->next_line;
    debug "pop_line called" if $DEBUG;
    $self->_unset_next_line;
    return $line;
}

sub give_back_next_line {
    my $self = shift;
    my $line = shift;

    debug "give_back_next_line called" if $DEBUG;
    if ($self->_has_next_line || $self->eof) {
	$self->_error("No way to give back previous line in reader when next one is loaded");
    }
    $self->_set_next_line($line);
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
    #if (! $class->meta->isa("Moose::Meta::Class")) {
    #	print "Adding parent\n";
    #	$hash{'parent'} //= $class;
    #}
    #print $class, "\n";
    if (exists($hash{'file'})) {
	$hash{'file'} = Path::Class::File->new($hash{'file'});
    }
    return $class->$orig(%hash);
};

sub BUILD {
    my $self = shift;
    my $args = shift;

    if ($self->has_parent) {
	#print "Have parent\n";
	$self->_set_cwd($self->parent->cwd);
    } else {
	#print "Have no parent\n";
	$self->_set_cwd(Path::Class::Dir->new('.')->cleanup);
    }
    if (exists($args->{'file'})) {
	my $file=$args->{'file'};
	#print "file: $file cwd: ",$self->cwd."", "\n" ;
	$self->_set_filename($file->stringify);
	if ($file->is_relative) {
	    $self->_set_cwd(Path::Class::Dir->new($self->cwd, $file->dir)->cleanup);
	    $file = Path::Class::File->new($self->cwd, $file->basename)->cleanup;
	} else {
	    $self->_set_cwd($file->dir->cleanup);
	}
	my $filename=$args->{'file'}->stringify;
	my $fh = $file->openr();
	binmode($fh, ":utf8");
	$self->_fh($fh);
	$self->_set_lineno(0);
	$self->_type('file');
	$self->_set_file($file->resolve);
    } elsif (exists($args->{'string'})) {
	my $content=$args->{'string'};
	open my $fh, "<", \$content;
	binmode($fh, ":utf8");
	$self->_fh($fh);
	$self->_set_lineno(0);
	$self->_set_filename("<>");
	$self->_type('string');
    } else {
	die "nothing to read!";
    }
    $self->_set_lineno($args->{'lineno'} - 1) if exists $args->{'lineno'};
    $self->_set_filename($args->{'filename'}) if exists $args->{'filename'};
    if (not($self->has_parent || $self->has_filename)) {
	die "Anonymous reader cannot be instanciated";
    }
}

sub newSubReader {
    my $self=shift;
    return $self->new(
	'parent' => $self,
	@_,
	);
}

1;
# ABSTRACT: Parse Ledger journals
