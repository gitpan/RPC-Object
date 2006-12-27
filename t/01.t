use strict;
use threads;
use threads::shared;
use Test::More qw(no_plan);
use Thread::Semaphore;

BEGIN {
    use_ok('RPC::Object');
    use_ok('RPC::Object::Broker');
}

require_ok('RPC::Object');
require_ok('RPC::Object::Broker');

my $s = Thread::Semaphore->new();
my $serv_port = 9000;

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

$name = 'Hahaha';
$o = RPC::Object->new("localhost:$serv_port", 'new', 't::TestModule', $name);
ok($o->get_name() eq $name);
ok($o->get_age() == 0);
ok($o->get_age() == 1);
