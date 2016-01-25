package Ledger::Journal::Python;
use Moose;
use namespace::sweep;
use Ledger::Util::ValueAttribute;

with (
    'Ledger::Role::HaveCachedText',
    'Ledger::Role::Readable',
    );

extends 'Ledger::Journal::Element';

has_value 'keyword' => (
    isa      => 'Constant',
    default  => 'python',
    );

has_value 'code' => (
    isa      => 'Str', # TODO: should ensure/verify the last line ends with \n
                       # TODO: should ensure/verify no blank line
                       # TODO: should ensure/verify always blank at line start
    required => 1,
    default  => '',
    );

sub load_from_reader {
    my $self = shift;
    my $reader = shift;

    $self->load_from_reader_helper(
	'reader' => $reader,
	'accept_with_blank_re' => qr/^python/,
	'parse_line_re' => qr<
	     ^(?<keyword>python)
	                    >x,
	'noaccept_error_msg' => "not starting a python block",
	'accept_error_msg' => "invalid python line (garbage data?)",
	'store' => ['keyword'],
	);
    my $code;
    my $next_line=$reader->pop_line;
    while (defined($next_line) && $next_line =~ /^\s+\S/) {
	$code .= $next_line;
	$next_line=$reader->pop_line;
    }
    $self->code($code);
    if (defined($next_line)) {
	$reader->give_back_next_line($next_line);
    }
};

sub compute_text {
    my $self = shift;
    return $self->keyword_str."\n".$self->code_str;
}

sub numlines {
    my $self = shift;
    my $str = $self->code_str;
    return 1 + $str =~ tr/\n//;;
}

1;
