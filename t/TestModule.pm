package t::TestModule;
use threads;
use threads::shared;

sub new {
    my ($class, $name) = @_;
    my $self = &share({});
    $self->{name} = $name;
    return bless $self, $class;
}

sub get_name : locked method {
    my ($self) = @_;
    return $self->{name};
}

sub get_age : locked method {
    my ($self) = @_;
    return $self->{age}++;
}

1;
