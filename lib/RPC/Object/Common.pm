package RPC::Object::Common;
use base qw(Exporter);
use constant FIND_INSTANCE => '_rpc_object_find_instance';
use constant RESPONSE_ERROR => 'e';
use constant RESPONSE_NORMAL => 'n';
use constant WANT_LIST => 'l';
use constant WANT_SCALAR => 's';
use strict;
use warnings;

our @EXPORT = qw(FIND_INSTANCE
                 RESPONSE_ERROR
                 RESPONSE_NORMAL
                 WANT_LIST
                 WANT_SCALAR
                 _log);

our $LOG_FH;

sub _log {
    if (defined $LOG_FH) {
        print $LOG_FH @_;
    }
}

1;
__END__
