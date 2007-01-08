use strict;
use warnings;
BEGIN {
    use Config;
    if (!$Config{useithreads}) {
        print ("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit 0;
    }
}
use IPC::Open2;
use Test::More qw(no_plan);

BEGIN {
    use_ok('RPC::Object');
    use_ok('RPC::Object::Broker');
}

require_ok('RPC::Object');
require_ok('RPC::Object::Broker');

my $port = 9000;

my ($out, $in);
my $pid = open2($out, $in, "$^X t/broker.pl $port");

my $o = RPC::Object->new("localhost:$port", 'new', 'TestModuleC');

eval { $o->call_to_die() };
ok($@ && $@ =~ /^DIED/);

eval { $o->call_to_exit() };
ok($@ && $@ =~ /^unexpected disconnection/);

END {
    kill 9, $pid;
    sleep 1;
}
