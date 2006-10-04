package RPC::Object;
use strict;
use warnings;
use Carp;
use IO::Socket::INET;
use Storable qw(thaw nfreeze);
use RPC::Object::Common;

our $VERSION = '0.01';
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

sub AUTOLOAD {
    my $self = shift;
    my $name = (split '::', our $AUTOLOAD)[-1];
    return _invoke($self->{host}, $self->{port}, $name, $self->{object}, @_);
}

sub _invoke {
    my $host = shift;
    my $port = shift;
    my $sock = IO::Socket::INET->new(PeerAddr => $host,
                                     PeerPort => $port,
                                     Proto => 'tcp',
                                     Type => SOCK_STREAM,
                                    );
    binmode $sock;
    print {$sock} nfreeze([wantarray ? WANT_LIST : WANT_SCALAR, @_]);
    $sock->shutdown(1);
    my $res = do { local $/; <$sock> };
    $sock->close();
    my ($stat, @ret) = @{thaw($res)};
    if ($stat eq RESPONSE_ERROR) {
        croak @ret;
    }
    elsif ($stat eq RESPONSE_NORMAL) {
        return wantarray ? @ret : $ret[0];
    }
    else {
        croak "Unknown response";
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
  $b = $RPC::Object::Broker->new($port);
  $b->start();

B<On client>

  use RPC::Object;
  $o = RPC::Object->new("$host:$port", 'method_a', 'The::Module');
  my $ans1 = $o->method_b($arg1, $arg2);
  my @ans2 = $o->method_c($arg3, $arg4);

=head1 DESCRIPTON

C<RPC::Object> is designed to be very simple and only works between
Perl codes, This makes its implementation only need some core Perl
modules, e.g. IO and Storable.

Other approaches like SOAP or XML-RPC are too heavy for simple tasks.

=head1 AUTHORS

Jianyuan Wu <jwu@cpan.org>

=head1 COPYRIGHT

Copyright 2006 by Jianyuan Wu <jwu@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
