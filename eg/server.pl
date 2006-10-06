BEGIN {
    push @INC, '../lib';
}

use RPC::Object::Broker;

local $RPC::Object::Broker::DEBUG = 1;

$b = RPC::Object::Broker->get_instance(9000);

$b->start();
