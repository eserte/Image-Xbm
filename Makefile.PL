use ExtUtils::MakeMaker ;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'         => 'Image::Xbm',
    'VERSION_FROM' => 'Xbm.pm', # finds $VERSION
    'DISTNAME'     => 'Image-Xbm',
    ($] >= 5.005 ?
        (
            ABSTRACT => 'Load, create, manipulate and save xbm image files.',
            AUTHOR   => 'Mark Summerfield <summer@perlpress.com>',
        ) : () ),
    'LIBS'         => [''],   # e.g., '-lm'
    'DEFINE'       => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'          => '',     # e.g., '-I/usr/include/other'
    'dist'         => { COMPRESS => "gzip -9", SUFFIX => "gz" },
) ;