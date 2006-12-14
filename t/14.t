use strict;
use threads;
use threads::shared;
use IO::File;
use Test::More;
use Thread::Semaphore;
use RPC::Object;
use RPC::Object::Broker;

BEGIN {
  SKIP: {
        eval {
            require threads;
        };
        $@ ? plan skip_all => 'RPC::Object need threads to run'
          : plan 'no_plan';
    }
}

my $s = Thread::Semaphore->new();
my $serv_port = 9000;

$s->down();
async {
    my $b = RPC::Object::Broker->get_instance($serv_port, 't::TestModule1');
    $s->up();
    $b->start();
}->detach;

$s->down();
my $name = 'Haha';
my $o = RPC::Object->get_instance("localhost:$serv_port", 'get_instance', 't::TestModule1', $name);
ok($o->get_name() eq $name);
ok($o->get_age() == 0);
ok($o->get_age() == 1);

my $name2 = 'Hahaha';
$o = RPC::Object->get_instance("localhost:$serv_port", 'get_instance', 't::TestModule1', $name2);
ok($o->get_name() eq $name);
ok($o->get_age() == 2);
ok($o->get_age() == 3);