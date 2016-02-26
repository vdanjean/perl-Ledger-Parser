package Ledger::Role::Element::AppliedTags;
use Moose::Role;
use namespace::sweep;
use Carp;

with (
    'Ledger::Role::HaveTags' => {
	-alias => {
	    '_reset_tags' => '_reset_tags_HaveTags',
	},
	-excludes => [
	     '_reset_tags',
	    ],
    }
    );

has '_inheritedTags' => (
    traits    =>  ['Hash'],
    is        => 'rw',
    isa       => 'HashRef[Maybe[Str]]',
    default  => sub { {} },
    handles  => {
	_inheritedTags_list     => 'elements',
	#_register_inheritedTags => 'set',
	_have_inheritedTags => 'count',
    },
    predicate    => '_inheritedTags_set',
    clearer      => '_reset_inheritedTags',
    );

sub _register_inheritedTags {
    my $self = shift;
    $self->_inheritedTags( { @_ } );
    $self->_tags_need_collect(1);
}

before '_register_inheritedTags' => sub {
    my $self = shift;

    if ($self->_inheritedTags_set) {
	carp "Inherited tags already set in ", $self->meta->name, ": ", $self->gettext.
	    "Either journal->cleanTags have not been called or the journal is read twice (due to includes for example)\n";
    }
};

sub _reset_tags {
    my $self = shift;
    my @tags = @_;
    
    if ($self->_inheritedTags_set && $self->_have_inheritedTags) {
	$self->_reset_tags_HaveTags($self->_inheritedTags_list);
	if (scalar(@tags)) {
	    $self->_add_valued_tag(@tags);
	}
    } else {
	$self->_reset_tags_HaveTags(@tags);
    }
}	

1;
