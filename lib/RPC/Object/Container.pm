package RPC::Object::Container;
use strict;
use threads;
use threads::shared;
use warnings;
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
    return $ref;
}

sub remove {
    my ($self, $ref) = @_;
    lock %$self;
    delete $self->{$ref};
}

sub get {
    my ($self, $ref) = @_;
    lock %$self;
    return $self->{$ref};
}

sub find {
    my ($self, $class) = @_;
    lock %$self;
    my $obj;
    for my $ref (keys %$self) {
        $obj = $self->{$ref};
        last if $class eq blessed $obj;
    }
    return $obj;
}

sub pop {
    my ($self, $class) = @_;
    lock %$self;
    my $obj;
    for my $ref (keys %$self) {
        $obj = $self->{$ref};
        if ($class eq blessed $obj) {
            delete $self->{$ref};
            last;
        }
        else {
            $obj = undef;
        }
    }
    return $obj;
}

sub _encode_ref {
    my ($obj) = @_;
    return refaddr $obj;
}

1;
__END__
