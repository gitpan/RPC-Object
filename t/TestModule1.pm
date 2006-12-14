package t::TestModule1;
use threads;
use threads::shared;

{
    my $instance : shared;
    sub get_instance {
        my ($class, $name) = @_;
        lock $instance;
        return $instance if $instance;
        $instance = &share({});
        $instance->{name} = $name;
        return bless $instance, $class;
    }
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
