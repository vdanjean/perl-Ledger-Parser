package Ledger::Role::HaveTags;
use Moose::Role;
use namespace::sweep;
use Carp;

requires '_collect_tags';

with (
    'Ledger::Role::IsUpdatable',
    );

has '_tags' => (
    traits    =>  ['Hash'],
    is        => 'rw',
    isa       => 'HashRef[Maybe[Str]]',
    required => 1,
    default  => sub { {} },
    handles  => {
	tag_names           => 'keys',
	tags                => 'elements',
	tag_pairs           => 'kv',
	has_no_tags         => 'is_empty',
	has_tags            => 'count',
	has_tag             => 'exists',
	tag0                => 'get',
        #all_named_values   => 'elements',
        #all_values         => 'values',
        #_register_value    => 'set',
	_add_valued_tag     => 'set',
        #_filter_types=> 'grep',
        #find_element   => 'first',
        #get_type    => 'get',
        #join_elements  => 'join',
        #count_types => 'count',
        #has_options    => 'count',
        #has_no_types=> 'is_empty',
        #sorted_options => 'sort',
    },
    lazy      => 1,
    );

has '_tags_need_collect' => (
    isa          => 'Bool',
    is           => 'rw',
    required     => 1,
    default      => 1,
    lazy         => 1,
    );

sub _reset_tags {
    my $self = shift;
    $self->_tags( { @_ } );
}

sub _add_simple_tag {
    my $self = shift;
    my $name = shift;
    return $self->_add_valued_tag($name, undef);
}

sub _merge_tags {
    my $self = shift;
    my $taggedObj = shift;
    return $self->_add_valued_tag($taggedObj->tags);
}

sub tag {
    my $self = shift;
    my $name = shift;
    if (!$self->has_tag($name)) {
	return undef;
    }
    return $self->tag($name) // "";
}

# Update before read access if required
for my $m ('tag_names', 'tags', 'tag_pairs', 'has_no_tags', 'has_tags',
	   'tag0', 'tag') {
    before $m => sub {
	my $self = shift;
	if ($self->_tags_need_collect) {
	    $self->_collect_tags;
	    $self->_tags_need_collect(0);
	}
    }
}

sub _update_tag_hook() {
    my $self = shift;
    $self->_tags_need_collect(1);
}

before 'register_update_hooks' => sub {
    my $self = shift;
    $self->register_update_hook(__PACKAGE__, "_update_tag_hook");
};

1;
