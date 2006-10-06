BEGIN {
    push @INC, '../lib';
}

use RPC::Object;



$o = RPC::Object->new('localhost:9000', 'get_blessed_instance', 'RPC::Object::Broker', 'TestModule');

$o->set_name('Hiya');

print $o->get_name(), "\n";

print $o->get_age(), "\n";

print $o->get_age(), "\n";


