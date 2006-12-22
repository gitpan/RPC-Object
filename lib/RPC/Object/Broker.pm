package RPC::Object::Broker;
use strict;
use threads;
use threads::shared;
use warnings;
use Carp;
use IO::Socket::INET;
use Scalar::Util qw(blessed);
use Storable qw(thaw nfreeze);
use RPC::Object::Common;
use RPC::Object::Container;

{
    my $instance;
    sub get_instance : locked {
        my ($class, $port, @preload) = @_;
        return $instance if defined $instance;
        $instance = &share({});
        $instance->{port} = $port;
        $instance->{preload} = &share({});
        $instance->{container} = &share(RPC::Object::Container->new());
        bless $instance, $class;
        $instance->_get_container()->insert($instance);
        for (@preload) {
            $instance->_load_module($_);
            $instance->{preload}{$_} = 1;
        }
        return $instance;
    }

}

sub _get_container : locked method {
    my ($self) = @_;
    return $self->{container};
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
                                     TimeOut => 10);
    binmode $sock;
    while (1) {
        my $conn = $sock->accept();
        next unless defined $conn;
        my $thr = async {
            $sock->close();
            my $res = do { local $/; <$conn> };
            $res = thaw($res);
            print $conn nfreeze($self->_handle($res));
            $conn->close();
        };
        $thr->detach();
        $conn->close();
    }
}

sub _handle {
    my ($self, $arg) = @_;
    my $context = shift @$arg;
    my $func = shift @$arg;
    my $ref = shift @$arg;
    my $obj;
    my $pack;
    my $container = $self->_get_container();

    $obj = $container->get($ref);
    $obj = $ref unless $obj;
    $pack = blessed $obj;
    $pack = $ref unless $pack;
    eval { $self->_load_module($pack) };
    return [RESPONSE_ERROR, $@] if $@;

    no strict;
    no warnings 'uninitialized';
    my @ret = $context eq WANT_SCALAR
      ? scalar eval { $obj->$func(@$arg) }
        : eval { $obj->$func(@$arg) };
    if (blessed $ret[0]) {
        $ret[0] = $container->insert($ret[0]);
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

1;
