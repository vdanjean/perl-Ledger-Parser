package Ledger::Journals;
use Moose;
use namespace::sweep;
use Ledger::Journal;

# DATE
# VERSION

with (
    'Ledger::Role::IsParent',
    );

has 'elements' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Ledger::Journal]',
    default  => sub { [] },
    required => 1,
    handles  => {
	all_journals     => 'elements',
	_add_journal     => 'push',
	_map_journals    => 'map',
	_filter_journals => 'grep',
	#find_element   => 'first',
	#get_element    => 'get',
	#join_elements  => 'join',
	#count_elements => 'count',
	#has_options    => 'count',
	#has_no_elements=> 'is_empty',
	#sorted_options => 'sort',
	empty          => 'is_empty',
    },
    init_arg => undef,
    );

has 'config' => (
    is         => 'rw',
    does       => 'Ledger::Role::Config',
    required   => 1,
    );

sub as_string {
    my $self = shift;
    $self->validate;
    return $self->_as_string;
}

sub journal {
    my $self = shift;
    die 'Invalid call to journal method in a '.$self->meta->name;
}

sub journals {
    my $self = shift;
    return $self;
}

sub add_journal {
    my $self = shift;
    my %opts = @_;

    if (defined($opts{'reader'})) {
	my $reader = $opts{'reader'};

	if ($reader->is_file) {
	    my $file=$reader->file;
	    my $filename=$file->stringify;
	    #print STDERR "Trying to load $filename\n";
	    my @jnx = $self->_filter_journals(sub {
		#if ($_->is_file) {
		#    print STDERR "  comparing to ".$_->file->stringify."\n";
		#};
		$_->is_file
		    && $_->file->stringify eq $filename
	    });
	    if (scalar(@jnx)>0) {
		my $journal=$jnx[0];
		#print STDERR "Reusing already loaded journal\n";
		return $journal;
	    }
	    #print STDERR "Must load $filename\n";
	    $opts{'file'}=$file;
	}
	my $journal=Ledger::Journal->new(
		%opts,
		'parent' => $self,
	    );
	if (! $journal->parsingOK) {
	    if ($self->config->die_if_parsing_error) {
		die "Aborting due to parsing error while reading ".
		    $reader->filename."\n";
	    }
	}
	$self->_add_journal($journal);
	return $journal;
    } else {
	die "No way to add a journal without a reader";
    }
};

1;
