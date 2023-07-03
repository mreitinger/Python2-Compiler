use 5.026001;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Python2::Internals::Ext',
    VERSION_FROM      => 'lib/Python2/Internals/Ext.pm',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Python2/Internals/Ext.pm',
    AUTHOR            => 'Mathias Reitinger <mathias.reitinger@rootprompt.at>',
    LICENSE           => 'perl',
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
