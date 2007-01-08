use strict;
use warnings;
BEGIN {
    unshift @INC, './t';
}
use RPC::Object::Broker;

my ($port, @preload) = @ARGV;

my $b = RPC::Object::Broker->new($port, @preload);

$b->start();
