package RPC::Object::Broker;
use strict;
use threads;
use threads::shared;
use warnings;
use Carp;
use IO::Socket::INET;
use Scalar::Util qw(blessed weaken refaddr);
use Storable qw(thaw nfreeze);
use RPC::Object::Common;

our $DEGUB = 0;

{
    my $instance : shared;
    sub get_instance {
        my ($class, $port, @preload) = @_;
        lock $instance;
        return $instance if $instance;
        $instance = &share({});
        $instance->{port} = $port;
        $instance->{object} = &share({});
        $instance->{preload} = &share({});
        bless $instance, $class;
        $instance->{object}{_encode_ref($instance)} = $instance;
        weaken $instance->{object}{_encode_ref($instance)};
        for (@preload) {
            eval { $instance->_load_module($_) };
            $instance->{preload}{$_} = 1;
        }
        return $instance;
    }
}

sub get_blessed_instance {
    my ($class, $rclass) = @_;
    my $self = $class->get_instance();
    lock %{$self->{object}};
    for my $ref (keys %{$self->{object}}) {
        my $obj = $self->{object}{$ref};
        if ($rclass eq blessed $obj) {
            delete $self->{object}{$ref};
            if (our $DEBUG) {
                print "REPLACE: $ref\n";
                for (keys %{$self->{object}}) {
                    print "Now: $_ : $self->{object}{$_} \n";
                }
            }
            return $obj;
        }
    }
    my $instance : shared;
    $instance = &share({});
    bless $instance, $rclass;
    return $instance;
}

sub start {
    my ($self) = @_;
    my $sock = IO::Socket::INET->new(LocalPort => $self->{port},
                                     Type => SOCK_STREAM,
                                     Reuse => 1,
                                     Listen => 10,
                                    );
    binmode $sock;
    while (my $conn = $sock->accept()) {
        my $thr = async {
            $sock->close();
            my $res = do { local $/; <$conn> };
            $res = thaw($res);
            print {$conn} nfreeze($self->handle($res));
            $conn->close();
        };
        $thr->detach();
        $conn->close();
    }
}

sub handle {
    my ($self, $arg) = @_;
    my $context = shift @$arg;
    my $func = shift @$arg;
    my $ref = shift @$arg;
    my $obj;
    my $pack;
    {
        lock %{$self->{object}};
        $obj = $self->{object}{$ref};
        $obj = $ref unless $obj;
        $pack = blessed $obj;
        $pack = $ref unless $pack;
        $self->_load_module($pack);
        if ($pack && $func eq RELEASE_REF) {
            delete $self->{object}{$ref};
            if (our $DEBUG) {
                print "DELETE: $ref\n";
                for (keys %{$self->{object}}) {
                    print "Now: $_ : $self->{object}{$_} \n";
                }
            }
            return [RESPONSE_NORMAL];
        }
    }
    my @ret;
    {
        no strict;
        @ret = $context eq WANT_SCALAR
          ? scalar eval { $obj->$func(@$arg) }
            : eval { $obj->$func(@$arg) };
        no warnings 'uninitialized';
        if (blessed $ret[0]) {
            $ref = _encode_ref($ret[0]);
            lock %{$self->{object}};
            $self->{object}{$ref} = $ret[0];
            if (our $DEBUG) {
                print "STORE: $ref, $ret[0]\n";
                for (keys %{$self->{object}}) {
                    print "Now: $_ : $self->{object}{$_} \n";
                }
            }
            $ret[0] = $ref;
        }
    }
    return $@ ? [RESPONSE_ERROR, $@] : [RESPONSE_NORMAL, @ret];
}

sub _load_module {
    my ($self, $pack) = @_;
    return if !$pack || $self->{preload}{$pack};
    if (our $DEBUG) {
        print "LOAD: $pack\n";
    }
    eval qq{ require $pack };
    die $@ if $@;
    return;
}

sub _encode_ref {
    my ($obj) = @_;
    return refaddr $obj;
}

1;
