use ExtUtils::MakeMaker;

# write the makefile
WriteMakefile(
    NAME		=> 'RunApp',
    VERSION_FROM	=> 'lib/RunApp.pm',
    PREREQ_PM		=> {
                             Template  => 0,
                             YAML  => 0,
                             App::Control  => 0,
                           },
    ABSTRACT_FROM       => 'lib/RunApp.pm',
    AUTHOR              => 'Chia-liang Kao <clkao@clkao.org>',
);
