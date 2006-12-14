package t::TestModule;
use threads;
use threads::shared;

sub new {
    my ($class, $name) = @_;
    my $self : shared;
    $self = &share({});
    $self->{name} = $name;
    return bless $self, $class;
}

sub get_name {
    my ($self) = @_;
    lock %{$self};
    return $self->{name};
}

sub get_age {
    my ($self) = @_;
    lock %{$self};
    return $self->{age}++;
}

1;
_END_
