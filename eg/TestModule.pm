package TestModule;
use strict;
use threads;
use threads::shared;
use warnings;

sub new {
    my ($class, $name) = @_;
    my $self : shared;
    $self = &share({});
    $self->{name} = $name;
    $self->{age} = 0;
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

