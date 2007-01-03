package RPC::Object::Broker;
use strict;
use threads;
use threads::shared;
use warnings;
use Carp;
use Scalar::Util qw(blessed weaken);
use Socket;
use Storable qw(thaw nfreeze);
use RPC::Object::Common;
use RPC::Object::Container;

sub new : locked {
    my ($class, $port, @preload) = @_;
    my  $self = &share({});
    $self->{port} = $port;
    $self->{preload} = &share({});
    $self->{container} = &share(RPC::Object::Container->new());
    bless $self, $class;
    for (@preload) {
        $self->_load_module($_);
        $self->{preload}{$_} = 1;
    }
    return $self;
}

sub _get_container : locked method {
    my ($self) = @_;
    return $self->{container};
}

sub start {
    my ($self) = @_;
    my $proto = getprotobyname('tcp') or croak $!;
    socket(SERVER, PF_INET, SOCK_STREAM, $proto) != -1 or croak $!;
    setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, pack('l', 1)) or croak $!;
    bind(SERVER, sockaddr_in($self->{port}, INADDR_ANY)) or croak $!;
    listen(SERVER, SOMAXCONN) or croak $!;
    while (1) {
        my $paddr = accept(CLIENT, SERVER);
        if (!$paddr) {
            carp $!;
            next;
        }
        async {
            binmode(CLIENT) or carp $!;
            my $req = eval { local $/; <CLIENT> };
            carp $@ if $@;
            my $oldfh = select(CLIENT);
            $| = 1;
            select($oldfh);
            eval { print CLIENT nfreeze($self->_handle(thaw($req))) };
            carp $@ if $@;
            shutdown(CLIENT, 2) != -1 or carp $!;
            close(CLIENT) or carp $!;
        }->detach();
        close(CLIENT) or carp $!;
    }
}

sub _handle {
    my ($self, $arg) = @_;
    my $context = shift @$arg;
    my $func = shift @$arg;
    my $ref = shift @$arg;
    my $container = $self->_get_container();

    if ($func eq FIND_INSTANCE && $ref eq __PACKAGE__) {
        my $ret = $container->find($arg->[0]);
        return [RESPONSE_NORMAL, $ret];
    }

    my $obj = $container->get($ref);
    $obj = $ref unless $obj;
    my $pack = blessed($obj);
    $pack = $ref unless $pack;
    eval { $self->_load_module($pack) };
    return [RESPONSE_ERROR, $@] if $@;

    no strict;
    no warnings 'uninitialized';
    my @ret;
    if ($context eq WANT_LIST) {
       @ret = eval { $obj->$func(@$arg) };
    } elsif ($context eq WANT_SCALAR) {
        $ret[0] = eval { $obj->$func(@$arg) };
    } elsif ($context eq WANT_VOID) {
        eval { $obj->$func(@$arg) };
    } else {
        return [RESPONSE_ERROR, 'unknown context'];
    }
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
    croak $@ if $@;
    return;
}

1;
