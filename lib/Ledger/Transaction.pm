package Ledger::Transaction;

use 5.010;
use DateTime;
use Log::Any '$log';
use Ledger::Util;
use Moo;

# VERSION

my $reset_line = sub { $_[0]->lineref(undef) };

has date        => (is => 'rw', trigger => $reset_line);
has seq         => (is => 'rw', trigger => $reset_line);
has description => (is => 'rw', trigger => $reset_line);
has entries     => (is => 'rw');
has lineref     => (is => 'rw'); # ref to line in journal->lines
has journal     => (is => 'rw');

sub BUILD {
    my ($self, $args) = @_;
    unless ($self->entries) {
        $self->entries([]);
    }
    if (!ref($self->date)) {
        $self->date(Ledger::Util::parse_date($self->date));
    }
    # re-set here because of trigger
    if (!defined($self->lineref)) {
        $self->lineref($args->{lineref});
    }
}

sub _die {
    my ($self, $msg) = @_;
    $self->journal->_die("Invalid transaction: $msg");
}

sub as_string {
    my ($self) = @_;
    my $rl = $self->journal->raw_lines;

    my $res = defined($self->lineref) ?
        ${$self->lineref} :
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

sub _bal_or_check {
    my ($self, $which) = @_;
    my $postings = $self->postings;

    my $num_p = 0;
    my $num_v = 0;
    my $num_vnb = 0;
    my $num_blank = 0;
    my %bal; # key=commodity
    for (@$postings) {
        $num_p++;
        $num_v++ if $_->is_virtual;
        my $is_vnb;
        if ($_->is_virtual && !$_->virtual_must_balance) {
            $num_vnb++;
            $is_vnb = 1;
        }
        $num_blank++ unless $_->amount;
        my $amt = $_->amount;
        next unless $amt;
        next if $is_vnb && $which eq 'check';
        my $number = $amt->[0];
        my $cmdity = $amt->[1];
        $bal{$cmdity} //= 0;
        $bal{$cmdity} += $number;
    }
    $log->tracef("num_p=%d, num_v=%d, num_blank=%d",
                 $num_p, $num_v, $num_blank);

    my @bal = map {[$bal{$_},$_]} grep {$bal{$_} != 0} keys %bal;
    if ($which eq 'check') {
        $self->_die("There must be at least 2 postings") if $num_p<2 && !$num_v;
        $self->_die("There must be at least 1 posting") if !$num_p;
        $self->_die("There must be at most 1 posting with blank amount")
            if $num_blank > 1;

        unless ($num_blank) {
            $self->_die(
                "doesn't balance (".
                    join(", ", map {Ledger::Util::format_amount($_)} @bal).
                        ")")
                if @bal;
        }
        return 1;
    } else {
        return [] if $num_blank;
        return \@bal;
    }
}

sub balance {
    my ($self) = @_;
    $self->_bal_or_check('bal');
}

sub is_balanced {
    my ($self) = @_;
    my $bal = $self->balance;
    @$bal == 0;
}

sub check {
    my ($self) = @_;
    $self->_bal_or_check('check');
}

1;
# ABSTRACT: Represent a Ledger transaction
__END__

=for Pod::Coverage BUILD

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 ATTRIBUTES

=head2 date => DATETIME OBJ

=head2 seq => INT or undef

Sequence of transaction in a day. Optional.

=head2 description => STR

=head2 lineref => REF TO STR

=head2 entries => ARRAY OF OBJS

Array of L<Ledger::Posting> or L<Ledger::Comment>

=head2 journal => OBJ

Pointer to L<Ledger::Journal> object.


=head1 METHODS

=head2 new(...)

=head2 $tx->as_string()

=head2 $tx->balance() => [[SCALAR,COMMODITY], ...]

Return transaction's balance. If a transaction balances, this method should
return [].

=head2 $tx->is_balanced() => BOOL

Return true if transaction is balanced, or false if otherwise.

=head2 $tx->check()

=head2 $tx->postings()

=cut
