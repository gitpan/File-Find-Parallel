use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';
warn "Optional ExtUtils::MakeMaker::Coverage not available\n" if $@;

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'File::Find::Parallel',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    VERSION_FROM  => 'lib/File/Find/Parallel.pm',
    ABSTRACT_FROM => 'lib/File/Find/Parallel.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'    => 0,
        'version'       => 0,
        'File::Tempdir' => '0.02',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'File-Find-Parallel-*' },
);
