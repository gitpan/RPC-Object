package RPC::Object::Broker;
use strict;
use threads;
use threads::shared;
use warnings;
use Carp;
use IO::Socket::INET;
use Scalar::Util qw(blessed weaken);
use Storable qw(thaw nfreeze);
use RPC::Object::Common;
use RPC::Object::Container;

{
    my $instance : shared;
    sub get_instance {
        my ($class, $port, @preload) = @_;
        lock $instance;
        return $instance if $instance;
        $instance = &share({});
        $instance->{port} = $port;
        $instance->{preload} = &share({});
        $instance->{container} = RPC::Object::Container->new();
        bless $instance, $class;
        $instance->_get_container()->insert($instance);
        weaken $instance;
        for (@preload) {
            $instance->_load_module($_);
            $instance->{preload}{$_} = 1;
        }
        return $instance;
    }
}

sub _get_blessed_instance {
    my $class = shift;
    my $method = shift;
    my $rclass = shift;
    my $self = $class->get_instance();
    my $obj = $self->_get_container()->find($rclass);
    return $obj if defined $obj;
    $self->_load_module($rclass);
    return $rclass->$method(@_);
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
        $obj = $self->_get_container()->get($ref);
        $obj = $ref unless $obj;
        $pack = blessed $obj;
        $pack = $ref unless $pack;
        eval { $self->_load_module($pack) };
        return [RESPONSE_ERROR, $@] if $@;
        if ($pack && $func eq RELEASE_REF) {
            $self->_get_container()->remove($ref);
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
            $ret[0] = $self->_get_container()->insert($ret[0]);
        }
    }
    return $@ ? [RESPONSE_ERROR, $@] : [RESPONSE_NORMAL, @ret];
}

sub _load_module {
    my ($self, $pack) = @_;
    _log "LOAD: $pack\n";
    return if $pack eq __PACKAGE__;
    return if !$pack || $self->{preload}{$pack};
    _log "LOADING: $pack\n";
    eval qq{ require $pack };
    die $@ if $@;
    return;
}

sub _get_container {
    my ($self) = @_;
    return $self->{container};
}

1;
