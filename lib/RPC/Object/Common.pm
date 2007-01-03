package RPC::Object::Common;
use base qw(Exporter);
use constant CONNECT_RETRY_MAX => '10';
use constant CONNECT_RETRY_WAIT => '2';
use constant FIND_INSTANCE => '_rpc_object_find_instance';
use constant RESPONSE_ERROR => 'e';
use constant RESPONSE_NORMAL => 'n';
use constant WANT_LIST => 'l';
use constant WANT_SCALAR => 's';
use constant WANT_VOID => 'v';
use strict;
use warnings;

our @EXPORT = qw(CONNECT_RETRY_MAX
                 CONNECT_RETRY_WAIT
                 FIND_INSTANCE
                 RESPONSE_ERROR
                 RESPONSE_NORMAL
                 WANT_LIST
                 WANT_SCALAR
                 WANT_VOID
                 _log);

our $LOG_FH;

sub _log {
    if (defined $LOG_FH) {
        print $LOG_FH @_;
    }
}

1;
__END__
