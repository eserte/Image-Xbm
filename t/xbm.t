#!/usr/bin/perl -w

# $Id$

# Copyright (c) 2000 Mark Summerfield. All Rights Reserved.
# May be used/distributed under the GPL.


use strict ;

use vars qw( $Loaded $Count $DEBUG $TRIMWIDTH ) ;

BEGIN { $| = 1 ; print "1..8\n" }
END   { print "not ok 1\n" unless $Loaded ; }

use Image::Xbm ;
$Loaded = 1 ;

$DEBUG = 1,  shift if @ARGV and $ARGV[0] eq '-d' ;
$TRIMWIDTH = @ARGV ? shift : 60 ;

report( "loaded module ", 0, '', __LINE__ ) ;

my( $i, $j, $k ) ;
my $fp = "/tmp/image-xbm" ;

eval {
    $i = Image::Xbm->new_from_string( "#####\n#---#\n-###-\n--#--\n--#--\n#####" ) ;
    die "Failed to create image correctly" unless
    $i->as_binstring eq '11111100010111000100001001111100' ;
} ;
report( "new_from_string()", 0, $@, __LINE__ ) ;

eval {
    $j = $i->new ;
    die "Failed to create image correctly" unless
    $j->as_binstring eq '11111100010111000100001001111100' ;
} ;
report( "new()", 0, $@, __LINE__ ) ;

eval {
    $i->save( "$fp-test1.xbm" ) ;
    die "Failed to save image" unless -e "$fp-test1.xbm" ;
} ;
report( "save()", 0, $@, __LINE__ ) ;

eval {
    $i = undef ;
    die "Failed to destroy image" if defined $i ;
    $i = Image::Xbm->new( -file => "$fp-test1.xbm" ) ;
    die "Failed to load image correctly" unless
    $i->as_binstring eq '11111100010111000100001001111100' ;
} ;
report( "load()", 0, $@, __LINE__ ) ;

eval {
    die unless $i->get( -file ) eq "$fp-test1.xbm" ;
} ;
report( "get()", 0, $@, __LINE__ ) ;

eval {
    die unless $i->get( -width ) == 5 ;
} ;
report( "get()", 0, $@, __LINE__ ) ;

eval {
    die unless $i->get( -height ) == 6 ;
} ;
report( "get()", 0, $@, __LINE__ ) ;


#eval {
#    $i->set( -width, 10 ) ;
#} ;
#report( "set()", 1, $@, __LINE__ ) ;


unlink "$fp-test1.xbm" ;

sub report {
    my $test = shift ;
    my $flag = shift ;
    my $e    = shift ;
    my $line = shift ;

    ++$Count ;
    printf "[%03d~%04d] $test(): ", $Count, $line if $DEBUG ;

    if( $flag == 0 and not $e ) {
        print "ok $Count\n" ;
    }
    elsif( $flag == 0 and $e ) {
        $e =~ tr/\n/ / ;
        if( length $e > $TRIMWIDTH ) { $e = substr( $e, 0, $TRIMWIDTH ) . '...' } 
        print "not ok $Count" ;
        print " \a($e)" if $DEBUG ;
        print "\n" ;
    }
    elsif( $flag ==1 and not $e ) {
        print "not ok $Count" ;
        print " \a(error undetected)" if $DEBUG ;
        print "\n" ;
    }
    elsif( $flag ==1 and $e ) {
        $e =~ tr/\n/ / ;
        if( length $e > $TRIMWIDTH ) { $e = substr( $e, 0, $TRIMWIDTH ) . '...' } 
        print "ok $Count" ;
        print " ($e)" if $DEBUG ;
        print "\n" ;
    }
}


