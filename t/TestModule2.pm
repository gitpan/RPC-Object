package t::TestModule2;
use threads;
use threads::shared;

sub new {
    my $class = shift;
    my $self = &share({});
    return bless $self, $class;
}

sub call : locked method {
    my ($self) = @_;
    $self->{context} = wantarray;
}

sub get_context : locked method {
    my ($self) = @_;
    return $self->{context};
}

1;
