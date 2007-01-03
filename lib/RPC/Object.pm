package RPC::Object;
use strict;
use threads;
use threads::shared;
use warnings;
use Carp;
use Socket;
use Storable qw(thaw nfreeze);
use RPC::Object::Common;

our $VERSION = '0.21';
$VERSION = eval $VERSION;

sub new {
    my $class = shift;
    my $url = shift;
    my ($host, $port) = $url =~ m{([^:]+):(\d+)};
    my $obj = _invoke($host, $port, @_);
    my $self = &share(\"$host:$port:$obj");
    return bless($self, $class);
}

sub get_instance {
    my $class = shift;
    my $url = shift;
    return $class->new($url,
                       FIND_INSTANCE,
                       'RPC::Object::Broker',
                       @_);
}

sub AUTOLOAD {
    my $self = shift;
    my @ns = split '::', our $AUTOLOAD;
    my $name = pop @ns;
    return unless __PACKAGE__ eq (join('::', @ns));
    my ($host, $port, $obj) = split(':', $$self);
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
    my $proto = getprotobyname('tcp') or croak $!;
    socket(SOCK, PF_INET, SOCK_STREAM, $proto) != -1 or croak $!;
    my $iaddr = inet_aton($host);
    croak $! unless defined $iaddr;
    my $addr = sockaddr_in($port, $iaddr);
    croak $! unless defined $addr;
    my $retry = 0;
    while (!connect(SOCK, $addr)) {
        ++$retry;
        croak 'connect retry exceed' if $retry > CONNECT_RETRY_MAX;
        sleep(CONNECT_RETRY_WAIT);
    }
    binmode(SOCK) or croak $!;
    my $oldfh = select(SOCK);
    $| = 1;
    select($oldfh);
    my $context = wantarray;
    $context
      = $context ? WANT_LIST : defined $context ? WANT_SCALAR : WANT_VOID;
    eval { print SOCK nfreeze([$context, @_]) };
    croak $@ if $@;
    shutdown(SOCK, 1) != -1 or croak $!;
    my $res = eval { local $/; <SOCK> };
    croak $@ if $@;
    close(SOCK) or croak $!;
    my ($stat, @ret) = eval { @{thaw($res)} };
    croak $@ if $@;
    if ($stat eq RESPONSE_ERROR) {
        carp @ret;
        return;
    }
    elsif ($stat eq RESPONSE_NORMAL) {
        return wantarray ? @ret : $ret[0];
    }
    else {
        croak "unknown response";
    }
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
modules, e.g. Socket and Storable.

Other approaches like SOAP or XML-RPC are too heavy for simple tasks.

B<Thread awareness>

All modules and objects invoked by C<RPC::Object> should aware the multi-threaded envrionment.

B<Constructor and Destructor>

The Module could name its constructor any meaningful name. it do not have to be C<new>, or C<create>, etc...

There is no guarantee that the destructor will be called as expected.

B<Global instance>

To allocate global instances, use the C<RPC::Object::new()> method. Then use the C<RPC::Object::get_instance()> method to access them.

=head1 KNOW ISSUES

B<Scalars leaked warning>

This is expected for now. The walkaround is to close STDERR.

B<Need re-bless RPC::Object>

C<threads::shared> prior to 0.95 does not support bless on shred refs, if an <RPC::Object> is passed across threads, it may need re-bless to C<RPC::Object>.

=head1 AUTHORS

Jianyuan Wu <jwu@cpan.org>

=head1 COPYRIGHT

Copyright 2006 by Jianyuan Wu <jwu@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
