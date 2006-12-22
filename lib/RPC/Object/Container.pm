package RPC::Object::Container;
use strict;
use threads;
use threads::shared;
use warnings;
use RPC::Object::Common;
use Scalar::Util qw(blessed refaddr weaken);

sub new {
    my ($class) = @_;
    my $self = &share({});
    bless $self, $class;
    return $self;
}

sub insert : locked method {
    my ($self, $obj) = @_;
    my $ref = _encode_ref($obj);
    $self->{$ref} = $obj;
    weaken $self->{$ref};
    _log "insert $obj as $ref\n";
    return $ref;
}

sub get : locked method {
    my ($self, $ref) = @_;
    my $obj = $self->{$ref};
    no warnings 'uninitialized';
    _log "get $obj as $ref\n";
    return $obj;
}

sub find : locked method {
    my ($self, $class) = @_;
    my $obj;
    for my $ref (keys %$self) {
        $obj = $self->{$ref};
        last if $class eq blessed $obj;
        $obj = undef;
    }
    no warnings 'uninitialized';
    _log "find $obj as $class\n";
    return $obj;
}

sub _encode_ref {
    my ($obj) = @_;
    return refaddr $obj;
}

1;
__END__
