package RPC::Object::Broker;
use strict;
use threads;
use threads::shared;
use warnings;
use Carp;
use Data::Dump qw(dump);
use IO::Socket::INET;
use Scalar::Util qw(blessed);
use Storable qw(thaw nfreeze);
#use RPC::Object;
use RPC::Object::Common;

{
    my $instance : shared;
    sub get_instance {
        my ($class, $port) = @_;
        return $instance if $instance;
        my $self : shared;
        $self = &share({});
        lock %{$self};
        $self->{port} = $port;
        share($self->{rclass});
        share($self->{object});
        $self->{rclass} = &share({});
        $self->{object} = &share({});
        bless $self, $class;
        $instance = $self;
        $self->{object}{ref $instance} = $instance;
        return $instance;
    }
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
    my $obj = shift @$arg;
    if (my $pack = blessed $obj) {
        $self->_load_module($pack);
        lock %{$self->{object}};
        $obj = $self->{object}{ref $obj};
    }
    else {
        $self->_load_module($obj);
    }
    my @ret;
    {
        no strict;
        @ret = $context eq WANT_SCALAR
          ? scalar eval { $obj->$func(@$arg) }
            : eval { $obj->$func(@$arg) };
        if (blessed $ret[0]) {
            lock %{$self->{object}};
            $self->{object}{ref $ret[0]} = $ret[0];
        }
    }
    return $@ ? [RESPONSE_ERROR, $@] : [RESPONSE_NORMAL, @ret];
}

sub _load_module {
    my ($self, $pack) = @_;
    eval qq{ require $pack };
    die $@ if $@;
    return;
}

1;
