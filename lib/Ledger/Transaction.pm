package Ledger::Transaction;

use 5.010;
use Log::Any '$log';
use Moo;

# VERSION

my $reset_line = sub { $_[0]->_line(undef) };

has date        => (is => 'rw', trigger => $reset_line);
has seq         => (is => 'rw', trigger => $reset_line);
has description => (is => 'rw', trigger => $reset_line);
has entries     => (is => 'rw');
has _line       => (is => 'rw');
has journal     => (is => 'rw');

sub as_string {
    my ($self) = @_;
    my $rl = $self->journal->raw_lines;

    my $res = defined($self->_line) ?
        $self->journal->raw_lines->[$self->_line] :
            $self->date->ymd . ($self->seq ? " (".$self->seq.")" : "") . " ".
                $self->description . "\n";
    for my $p (@{$self->entries}) {
        $res .= $p->as_string;
    }
    $res;
}

sub postings {
    my ($self) = @_;
    [grep {$_->isa('Ledger::Posting')} @{$self->entries}];
}


1;
# ABSTRACT: Represent a Ledger transaction
__END__

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 ATTRIBUTES

=head2 date => DATETIME OBJ

=head2 seq => INT or undef

Sequence of transaction in a day. Optional.

=head2 description => STR

=head2 entries => ARRAY OF OBJS

Array of L<Ledger::Posting> or L<Ledger::Comment>

=head2 journal => OBJ

Pointer to L<Ledger::Journal> object.

=cut
