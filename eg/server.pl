BEGIN {
    push @INC, '../lib';
}

use RPC::Object::Broker;

$b = RPC::Object::Broker->get_instance(9000);

$b->start();
