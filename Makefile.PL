use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'RPC::Object',
    VERSION_FROM      => 'lib/RPC/Object.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/RPC/Object.pm',
       AUTHOR         => 'Jianyuan Wu <jwu@cpan.org>') : ()),
);
