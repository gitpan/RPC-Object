package RPC::Object::Common;
use base qw(Exporter);
use constant RELEASE_REF => 'rpc_object_release';
use constant RESPONSE_ERROR => 'e';
use constant RESPONSE_NORMAL => 'n';
use constant WANT_LIST => 'l';
use constant WANT_SCALAR => 's';
use strict;
use warnings;

our @EXPORT = qw(
                 RELEASE_REF
                 RESPONSE_ERROR
                 RESPONSE_NORMAL
                 WANT_LIST
                 WANT_SCALAR
                );

1;
__END__
