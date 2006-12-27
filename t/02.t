use strict;
use threads;
use threads::shared;
use Test::More qw(no_plan);
use Thread::Semaphore;
use RPC::Object;
use RPC::Object::Broker;

my $s = Thread::Semaphore->new();
my $serv_port = 9000;

open $RPC::Object::Common::LOG_FH, '>', 'testlog.txt';

$s->down();
async {
    my $b = RPC::Object::Broker->new($serv_port, 't::TestModule');
    $s->up();
    $b->start();
}->detach;

$s->down();
my $name = 'Haha';
my $o = RPC::Object->new("localhost:$serv_port", 'new', 't::TestModule', $name);
ok($o->get_name() eq $name);
ok($o->get_age() == 0);
ok($o->get_age() == 1);

$name = 'Hahaha';
$o = RPC::Object->new("localhost:$serv_port", 'new', 't::TestModule', $name);
ok($o->get_name() eq $name);
ok($o->get_age() == 0);
ok($o->get_age() == 1);
