use strict;
use threads;
use threads::shared;
use Test::More qw(no_plan);
use Thread::Semaphore;
use RPC::Object;
use RPC::Object::Broker;

my $s = Thread::Semaphore->new();
my $serv_port = 9000;

open local $RPC::Object::Common::LOG_FH, ">", 'test_11.log';

$s->down();
async {
    my $b = RPC::Object::Broker->new($serv_port);
    $s->up();
    $b->start();
}->detach;

$s->down();
my $name = 'Haha';
my $o = RPC::Object->new("localhost:$serv_port", 'new', 't::TestModule', $name);
ok($o->get_name() eq $name);
ok($o->get_age() == 0);
ok($o->get_age() == 1);

$o = RPC::Object->get_instance("localhost:$serv_port", 't::TestModule');
ok($o->get_name() eq $name);
ok($o->get_age() == 2);
ok($o->get_age() == 3);
