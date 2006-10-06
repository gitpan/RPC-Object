BEGIN {
    push @INC, '../lib';
}

use RPC::Object;

$o = RPC::Object->new('localhost:9000', 'new', 'TestModule', 'Jianyuan');

print $o->get_name(), "\n";

print $o->get_age(), "\n";
print $o->get_age(), "\n";


$o->rpc_object_release();
