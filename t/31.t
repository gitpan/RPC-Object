BEGIN {
    use Config;
    if (!$Config{useithreads}) {
        print ("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit 0;
    }
}

use strict;
use threads;
use threads::shared;
use Test::More qw(no_plan);
use Thread::Semaphore;
use RPC::Object;
use RPC::Object::Broker;

my $s = Thread::Semaphore->new();
my $serv_port = 9000;

$s->down();
async {
    my $b = RPC::Object::Broker->new($serv_port);
    $s->up();
    $b->start();
}->detach;

$s->down();

my $o = RPC::Object->new("localhost:$serv_port", 'new', 't::TestModule2');

$o->call();
no warnings 'uninitialized';
ok($o->get_context() == undef);
scalar $o->call();
ok(!$o->get_context());
my @ret = $o->call();
ok($o->get_context());


