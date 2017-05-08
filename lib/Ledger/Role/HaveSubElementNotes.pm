package Ledger::Role::HaveSubElementNotes;
use Moose::Role;
use namespace::sweep;

sub addComment {
    my $self=shift;
    my $comment=shift;
    
    my $hc={
	'note.PlainNote' => {
	    'comment' => $comment // '',
	}
    };
    return $self->_add(ref($self)."::Note", $hc);
}

sub addTag {
    my $self=shift;
    my $name=shift;
    my $value=shift;
    
    
    my $hc={
	'note.TaggedValue' => {
	    'name' => $name // 'MissingTagName',
	    'value' => $value // '',
	}
    };
    return $self->_add(ref($self)."::Note", $hc);
}

1;
