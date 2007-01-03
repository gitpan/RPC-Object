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

my $name = 'Haha';
my $o = &share({});
$o->{obj} = RPC::Object->new("localhost:$serv_port", 'get_instance', 't::TestModule1', $name);
my $r = $o->{obj};
bless $r, 'RPC::Object';
ok($r->get_name() eq $name);
ok($r->get_age() == 0);
ok($r->get_age() == 1);

