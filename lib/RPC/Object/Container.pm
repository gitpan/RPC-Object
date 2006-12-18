package RPC::Object::Container;
use strict;
use threads;
use threads::shared;
use warnings;
use RPC::Object::Common;
use Scalar::Util qw(blessed refaddr);

sub new {
    my ($class) = @_;
    my $self : shared;
    $self = &share({});
    bless $self, $class;
    return $self;
}

sub insert {
    my ($self, $obj) = @_;
    lock %$self;
    my $ref = _encode_ref($obj);
    $self->{$ref} = $obj;
    _log "insert $obj as $ref\n";
    return $ref;
}

sub remove {
    my ($self, $ref) = @_;
    lock %$self;
    delete $self->{$ref};
    _log "remove $ref\n";
}

sub get {
    my ($self, $ref) = @_;
    lock %$self;
    my $obj = $self->{$ref};
    no warnings 'uninitialized';
    _log "get $obj as $ref\n";
    return $obj;
}

sub find {
    my ($self, $class) = @_;
    lock %$self;
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
