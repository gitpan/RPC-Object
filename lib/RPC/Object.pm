package RPC::Object;
use strict;
use warnings;
use Carp;
use Socket;
use Storable qw(thaw nfreeze);
use RPC::Object::Common;

our $VERSION = '0.16';
$VERSION = eval $VERSION;

sub new {
    my $class = shift;
    my $url = shift;
    my ($host, $port) = $url =~ m{([^:]+):(\d+)};
    my $obj = _invoke($host, $port, @_);
    my $self = &share({});
    %$self = (host => $host, port => $port, object => $obj);
    return bless($self, $class);
}

sub get_instance {
    my $class = shift;
    my $url = shift;
    my $self = $class->new($url,
                           FIND_INSTANCE,
                           'RPC::Object::Broker',
                           @_);
    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    my @ns = split '::', our $AUTOLOAD;
    my $name = pop @ns;
    return unless __PACKAGE__ eq (join('::', @ns));
    my $host = $self->{host};
    my $port = $self->{port};
    my $obj = $self->{object};
    if ($name eq 'DESTROY') {
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
    my $proto = getprotobyname('tcp');
    socket(SOCK, PF_INET, SOCK_STREAM, $proto);
    my $iaddr = inet_aton($host);
    my $addr = sockaddr_in($port, $iaddr);
    while (!connect(SOCK, $addr)) {
        sleep(1);
    }
    binmode(SOCK);
    select(SOCK);
    $| = 1;
    select(STDOUT);
    print SOCK nfreeze([wantarray ? WANT_LIST : WANT_SCALAR, @_]);
    shutdown(SOCK, 1);
    my $res = do { local $/; <SOCK> };
    close(SOCK);
    my ($stat, @ret) = @{thaw($res)};
    if ($stat eq RESPONSE_ERROR) {
        carp @ret;
    }
    elsif ($stat eq RESPONSE_NORMAL) {
        return wantarray ? @ret : $ret[0];
    }
    else {
        carp "Unknown response";
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
  $b = $RPC::Object::Broker->new($port, @preload_modules);
  $b->start();

B<On client>

  use RPC::Object;
  $o = RPC::Object->new("$host:$port", 'method_a', 'TestModule');
  my $ans1 = $o->method_b($arg1, $arg2);
  my @ans2 = $o->method_c($arg3, $arg4);

  # To access the global instance
  # allocate and initialize first,
  RPC::Object->new("$host:$port", 'method_a', 'TestModule');
  ...
  $global = RPC::Object->get_instance("$host:$port", 'TestModule');

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

There is no guarantee that the destructor will be called as expected.

B<Global instance>

To allocate and access global instances, use the C<RPC::Object::get_instance()> method.

=head1 AUTHORS

Jianyuan Wu <jwu@cpan.org>

=head1 COPYRIGHT

Copyright 2006 by Jianyuan Wu <jwu@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
