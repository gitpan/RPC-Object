package RPC::Object;
use strict;
use warnings;
use Carp;
use IO::Socket::INET;
use Storable qw(thaw nfreeze);
use RPC::Object::Common;

our $VERSION = '0.11';
$VERSION = eval $VERSION;

sub new {
    my $class = shift;
    my $url = shift;
    my ($host, $port) = $url =~ m{([^:]+):(\d+)};
    my $obj = _invoke($host, $port, @_);
    my $self = {
                host => $host,
                port => $port,
                object => $obj,
               };
    return bless $self, $class;
}

sub get_instance {
    my $class = shift;
    my $url = shift;
    return $class->new($url, '_get_blessed_instance', 'RPC::Object::Broker', @_);
}

sub AUTOLOAD {
    my $self = shift;
    my $name = (split '::', our $AUTOLOAD)[-1];
    my $host = $self->{host};
    my $port = $self->{port};
    my $obj = $self->{object};
    if ($name eq 'DESTROY') {
        return;
    }
    elsif ($name eq RELEASE_REF) {
        _invoke($host, $port, $name, $obj, @_);
        $self->{object} = undef;
        return;
    }
    elsif ($obj) {
        return _invoke($host, $port, $name, $obj, @_);
    }
    return;
}

sub _invoke {
    my $host = shift;
    my $port = shift;
    my $sock;
    my $connected;
    while (!$connected) {
        eval {
            $sock = IO::Socket::INET->new(PeerAddr => $host,
                                          PeerPort => $port,
                                          Proto => 'tcp',
                                          Type => SOCK_STREAM,
                                         );
            binmode $sock;
        };
        $connected = !$@;
        sleep 1 unless $connected;
    }
    print {$sock} nfreeze([wantarray ? WANT_LIST : WANT_SCALAR, @_]);
    $sock->shutdown(1);
    my $res = do { local $/; <$sock> };
    $sock->close();

    my ($stat, @ret) = @{thaw($res)};
    if ($stat eq RESPONSE_ERROR) {
        die @ret;
    }
    elsif ($stat eq RESPONSE_NORMAL) {
        return wantarray ? @ret : $ret[0];
    }
    else {
        die "Unknown response";
    }
    return;
}

1;
__END__

=head1 NAME

RPC::Object - A lightweight implementation for remote procedure calls

=head1 SYNOPSIS

B<On server>

  use RPC::Object::Broker;
  $b = $RPC::Object::Broker->get_instance($port, @preload_modules);
  $b->start();

B<On client>

  use RPC::Object;
  $o = RPC::Object->new("$host:$port", 'method_a', 'TestModule');
  my $ans1 = $o->method_b($arg1, $arg2);
  my @ans2 = $o->method_c($arg3, $arg4);

  # or access the global instance
  $o2 = RPC::Object->get_instance("$host:$port", 'method_x', 'TestModule2');

B<TestModule>

  package TestModule;
  use threads;
  ...
  sub method_a {
      my $class = shift;
      my $self : shared;
      ...
      return bless $self, $class;
  }

  sub method_b {
      ...
  }
  ...

B<TestModule2>

  package TestModule2;
  use threads;
  ...
  {
     my $instance : share;
     sub method_x {
         ...
         return $instance;
     }
  }
  ...

Please see more examples in the test scripts.

=head1 DESCRIPTON

C<RPC::Object> is designed to be very simple and only works between
Perl codes, This makes its implementation only need some core Perl
modules, e.g. IO and Storable.

Other approaches like SOAP or XML-RPC are too heavy for simple tasks.

B<Thread awareness>

All modules and objects invoked by C<RPC::Object> should aware the multi-threaded envrionment.

B<Constructor and Destructor>

The Module could name its constructor any meaningful name. it do not have to be C<new>, or C<create>, etc...

To release an object, use C<RPC::Object::rpc_object_release>, e.g.

  $o = RPC::Object->new("$host:$port", 'method_a', 'TestModule');
  $o->rpc_object_release();

B<Global instance>

There are two ways to allocate and access global instances: a) use the preload module list to load the module at server side, and use the C<RPC::Object::new()> method; b) use the C<RPC::Object::get_instance()> method. The performance of method a may be better as modules are only loaded once.

=head1 AUTHORS

Jianyuan Wu <jwu@cpan.org>

=head1 COPYRIGHT

Copyright 2006 by Jianyuan Wu <jwu@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
