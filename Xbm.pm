package Image::Xbm ;    # Documented at the __END__

# $Id: Xbm.pm,v 1.3 2000/04/30 18:36:52 root Exp root $ 

use strict ;

use vars qw( $VERSION ) ;
$VERSION = '1.00' ;

use Carp qw( carp croak ) ;
use Symbol () ;


# Private class data 

# If you inherit don't clobber these fields!
my @FIELD = qw( -file -width -height -hotx -hoty -bits 
                -setch -unsetch -sethotch -unsethotch ) ;

my @MASK  = ( 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80 ) ;


### Private methods
#
# _class_get    class   object
# _class_set    class   object
# _get                  object
# _set                  object
# _vec                  object

{
    my( $setch, $unsetch, $sethotch, $unsethotch ) = ( '#', '-', 'H', 'h', ) ;

    sub _class_get { # Class and object method
        my $self  = shift ;
        my $class = ref( $self ) || $self ;

        my $field = shift ;

        if(    $field eq '-setch' ) {
            $setch ;
        }
        elsif( $field eq '-unsetch' ) {
            $unsetch ;
        }
        elsif( $field eq '-sethotch' ) {
            $sethotch ;
        }
        elsif( $field eq '-unsethotch' ) {
            $unsethotch ;
        }
        else {
            croak "_class_get() invalid field `$field'" ;
        }
    }


    sub _class_set { # Class and object method
        my $self  = shift ;
        my $class = ref( $self ) || $self ;

        my $field = shift ;
        my $val   = shift ;

        croak "_class_set() `$field' has no value" unless defined $val ;

        if(    $field eq '-setch' ) {
            $setch      = $val ;
        }
        elsif( $field eq '-unsetch' ) {
            $unsetch    = $val ;
        }
        elsif( $field eq '-sethotch' ) {
            $sethotch   = $val ;
        }
        elsif( $field eq '-unsethotch' ) {
            $unsethotch = $val ;
        }
        else {
            croak "_class_set() invalid field `$field'" ;
        }
     }
}


sub _get { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;
   
    $self->{shift()} ;
}


sub _set { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;
    
    my $field = shift ;

    $self->{$field} = shift ;
}


sub _vec { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my $offset = shift ;

    # No range checking
    CORE::vec( $self->{-bits}, $offset, 1 ) = shift if @_ ;

    CORE::vec( $self->{-bits}, $offset, 1 ) ;
}


### Public methods

sub new_from_string { # Class and object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;

    my @line ;
    
    if( @_ > 1 ) {
        chomp( @line = @_ ) ;
    }
    else {
        @line = split /\n/, $_[0] ;
    }

    my $setch      = $class->get( -setch ) ;
    my $sethotch   = $class->get( -sethotch ) ;
    my $unsethotch = $class->get( -unsethotch ) ;
    my $width ;
    my $y = 0 ;
    
    $self = $class->new( -width => 8192, -height => 8192 ) ;

    foreach my $line ( @line ) {
        next if $line =~ /^\s*$/ ;
        unless( defined $width ) {
            $width = length $line ;
            $self->_set( -width => $width ) ;
        }
        for( my $x = 0 ; $x < $width ; $x++ ) {
            my $c = substr( $line, $x, 1 ) ;
            $self->xy( $x, $y, $c eq $setch ? 1 : $c eq $sethotch ? 1 : 0 ) ;
            $self->set( -hotx => $x, -hoty => $y ) 
            if $c eq $sethotch or $c eq $unsethotch ;
        }
        $y++ ;
    }

    $self->_set( -height => $y ) ;

    $self ;
}


sub new { # Class and object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;
    my $obj   = ref $self ? $self : undef ; 
    my %arg   = @_ ;

    # Defaults
    $self = {
            -hotx => -1, # This is used to signify unset
            -hoty => -1, # This is used to signify unset
            -bits => '',
        } ;

    bless $self, $class ;

    # If $obj->new copy original object's data
    if( defined $obj ) {
        foreach my $field ( @FIELD ) {
            $self->_set( $field, $obj->get( $field ) ) ;
        }
    }

    # Any options specified override
    foreach my $field ( @FIELD ) {
        $self->_set( $field, $arg{$field} ) if defined $arg{$field} ;
    }

    $self->load if $self->get( -file ) and not $self->get( -bits ) ;

    foreach my $field ( qw( -width -height ) ) {
        croak "new() $field must be set" unless defined $self->get( $field ) ;
    }

    $self ;
}


sub get { # Object method (and class method for class attributes)
    my $self  = shift ;
    my $class = ref( $self ) || $self ;
  
    my $field = shift ;

    if( $field =~ /^-(?:un)?set(?:hot)?ch$/o ) {
        $class->_class_get( $field ) ;
    }
    else {
        $self->_get( $field ) ;
    }
}


sub set { # Object method (and class method for class attributes)
    my $self  = shift ;
    my $class = ref( $self ) || $self ;
    
    while( @_ ) {
        my $field = shift ;
        my $val   = shift ;

        carp "set() -field has no value" unless defined $val ;
        carp "set() $field is read-only"  
        if $field eq '-bits' or $field eq '-width' or $field eq '-height' ;
        carp "set() -hotx `$val' is out of range" 
        if $field eq '-hotx' and ( $val < -1 or $val >= $self->get( -width ) ) ;
        carp "set() -hoty `$val' is out of range" 
        if $field eq '-hoty' and ( $val < -1 or $val >= $self->get( -height ) ) ;

        if( $field =~ /^-(?:un)?set(?:hot)?ch$/o ) {
            $class->_class_set( $field, $val ) ;
        }
        else {
            $self->_set( $field, $val ) ;
        }
    }
}


sub xy { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my( $x, $y, $val ) = @_ ; 

    my $width = $self->get( -width ) ;

    croak "xy() x `$x' is out of range" unless $x >= 0 and $x < $width ;
    croak "xy() y `$y' is out of range" 
    unless $y >= 0 and $y < $self->get( -height ) ;

    $self->_vec( ( $y * $width ) + $x, $val ) if defined $val ;

    $self->_vec( ( $y * $width ) + $x ) ;
}


sub vec { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my( $offset, $val ) = @_ ; 

    # No range checking
    $self->_vec( $offset, $val ) if defined $val ;

    $self->_vec( $offset ) ;
}


sub is_equal { # Object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;
    my $obj   = shift ;

    croak "is_equal() can only compare $class objects" 
    unless ref $obj and $obj->isa( __PACKAGE__ ) ;

    # We ignore -file, -hotx and -hoty when we consider equality.
    return 0 if $self->get( -width )  != $obj->get( -width )  or 
                $self->get( -height ) != $obj->get( -height ) or
                $self->get( -bits )   ne $obj->get( -bits ) ;

    1 ;
}


sub as_string { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my $hotch      = shift || 0 ;
    my $setch      = $self->get( -setch ) ;
    my $unsetch    = $self->get( -unsetch ) ;
    my $sethotch   = $self->get( -sethotch ) ;
    my $unsethotch = $self->get( -unsethotch ) ;
    my $hotx       = $self->get( -hotx ) ;
    my $hoty       = $self->get( -hoty ) ;
    my $string     = '' ;

    for( my $y = 0 ; $y < $self->get( -height ) ; $y++ ) {
        for( my $x = 0 ; $x < $self->get( -width ) ; $x++ ) {
            if( $hotch and $x == $hotx and $y == $hoty ) {
                $string .= $self->xy( $x, $y ) ? $sethotch : $unsethotch ;
            }
            else {
                $string .= $self->xy( $x, $y ) ? $setch : $unsetch ;
            }
        }
        $string .= "\n" ;
    }

    $string ;
}


sub as_binstring { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    unpack "b*", $self->get( -bits ) ;
}


# The algorithm is based on the one used in Thomas Boutell's GD library.
sub load { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my $file  = shift() || $self->get( -file ) ;

    croak "load() no file specified" unless $file ;

    $self->set( -file, $file ) ;

    my( @val, $width, $height, $hotx, $hoty ) ;
    local $_ ;
    my $fh = Symbol::gensym ;

    open $fh, $file or croak "load() failed to open `$file': $!" ;

    while( <$fh> ) {
        $width  = $1, next if /#define.*width\s+(\d+)/o ; 
        $height = $1, next if /#define.*height\s+(\d+)/o ; 
        $hotx   = $1, next if /#define.*_x_hot\s+(\d+)/o ; 
        $hoty   = $1, next if /#define.*_y_hot\s+(\d+)/o ; 
        push @val, map { hex } /0[xX]([A-Fa-f\d][A-Fa-f\d]?)/g ; 
    }
    croak "load() failed to find dimension(s) in `$file'" 
    unless defined $width and defined $height ;

    close $fh or croak "load() failed to close `$file': $!" ;

    $self->_set( -width,  $width ) ;
    $self->_set( -height, $height ) ;
    $self->set( -hotx,    defined $hotx ? $hotx : -1 ) ; 
    $self->set( -hoty,    defined $hoty ? $hoty : -1 ) ;

    my( $x, $y ) = ( 0, 0 ) ;
    my $bitindex = 0 ;
    my $bits     = '' ;
    BYTE:
    for( my $i = 0 ; ; $i++ ) {
        BIT:
        for( my $bit = 1 ; $bit <= 128 ; $bit <<= 1 ) {
            vec( $bits, $bitindex++, 1 ) = ( $val[$i] & $bit ) ? 1 : 0 ;
            $x++ ;
            if( $x == $width ) {
                $x = 0 ;
                $y++ ;
                last BYTE if $y == $height ;
                last BIT ;
            }
        }
    }

    $self->_set( -bits, $bits ) ;
}


# The algorithm is based on the X Consortium's bmtoa program.
sub save { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my $file   = shift() || $self->get( -file ) ;

    croak "save() no file specified" unless $file ;

    $self->set( -file, $file ) ;

    my $width  = $self->get( -width ) ;
    my $height = $self->get( -height ) ;
    my $hotx   = $self->get( -hotx ) ;
    my $hoty   = $self->get( -hoty ) ;

    my $fh = Symbol::gensym ;
    open $fh, ">$file" or croak "save() failed to open `$file': $!" ;

    $file =~ s,^.*/,,o ;            
    $file =~ s/\.xbm$//o ;         
    $file =~ tr/[-_a-za-z0-9]/_/c ;
    
    print $fh "#define ${file}_width $width\n#define ${file}_height $height\n" ;
    print $fh "#define ${file}_x_hot $hotx\n#define ${file}_y_hot $hoty\n" 
    if $hotx > -1 and $hoty > -1 ; 
    print $fh "static unsigned char ${file}_bits[] = {\n" ;

    my $padded = ( $width & 7 ) != 0 ;
    my @char ;
    my $char = 0 ;
    for( my $y = 0 ; $y < $height ; $y++ ) {
        for( my $x = 0 ; $x < $width ; $x++ ) {
            my $mask = $x & 7 ;
            $char[$char] = 0 unless defined $char[$char] ;
            if( $self->xy( $x, $y ) ) {
                $char[$char] |= $MASK[$mask] ;
            }
            $char++ if $mask == 7 ;
        }
        $char++ if $padded ;
    }

    my $i = 0 ;
    my $bytes_per_char = ( $width + 7 ) / 8 ;
    foreach $char ( @char ) {
        printf $fh " 0x%02x", $char ;
        print  $fh "," unless $i == $#char ;
        print  $fh "\n" if $i % 12 == 11 ;
        $i++ ;
    }
    print $fh " } ;\n";

    close $fh or croak "save() failed to close `$file': $!" ;
}


1 ;


__END__

=head1 NAME

Image::Xbm - Load, create, manipulate and save xbm image files.

=head1 SYNOPSIS

    use Image::Xbm ;

    my $j = Image::Xbm->new( -file, 'balArrow.xbm' ) ;

    my $i = Image::Xbm->new( -width => 10, -height => 16 ) ;

    my $h = $i->new ; # Copy of $i

    my $p = Image::Xbm->new_from_string( "###\n#-#\n###" ) ;

    my $q = $p->new_from_string( "H##", "#-#", "###" ) ;

    $i->xy( 5, 8, 1 ) ;           # Set a bit
    print '1' if $i->xy( 9, 3 ) ; # Get a bit

    $i->vec( 24, 0 ) ;            # Set a bit using a vector offset
    print '1' if $i->vec( 24 ) ;  # Get a bit using a vector offset

    print $i->get( -width ) ;     # Get and set object and class attributes
    $i->set( -height, 15 ) ;

    $i->load( 'test.xbm' ) ;
    $i->save ;

    print "equal\n" if $i->is_equal( $j ) ; 

    print $j->as_string ;

    #####-
    ###---
    ###---
    #--#--
    #---#-
    -----#

    print $j->as_binstring ;

    1111101110001110001001001000100000010000


=head1 DESCRIPTION

=head2 new()

    my $i = Image::Xbm->new( -file => 'test.xbm' ) ;
    my $j = Image::Xbm->new( -width => 12, -height => 18 ) ;
    my $k = $i->new ;

We can create a new xbm image by reading in a file, or by creating an image
from scratch (all the bits are unset by default), or by copying an image
object that we created earlier.

If we set C<-file> then all the other arguments are ignored (since they're
taken from the file). If we don't specify a file, C<-width> and C<-height> are
mandatory.

Note that if you are creating an image from scratch you should not set
C<-file> when you call C<new>; you should either C<set> it later or simply
include the filename in any call to C<save> which will set it for you.

=over

=item C<-file>

The name of the file to read when creating the image. May contain a full path.
This is also the default name used for C<load>ing and C<save>ing, though it
can be overridden when you load or save.

=item C<-width>

The width of the image; taken from the file or set when the object is created;
read-only.

=item C<-height>

The height of the image; taken from the file or set when the object is created;
read-only.

=item C<-hotx>

The x-coord of the image's hotspot; taken from the file or set when the object
is created. Set to -1 if there is no hotspot.

=item C<-hoty>

The y-coord of the image's hotspot; taken from the file or set when the object
is created. Set to -1 if there is no hotspot.

=item C<-bits>

The bit vector that stores the image; read-only.

=back

=head2 new_from_string()

    my $p = Image::Xbm->new_from_string( "###\n#-#\n###" ) ;
    my $q = $p->new_from_string( "H##", "#-#", "###" ) ;
    my $r = $p->new_from_string( $p->as_string ) ;

Create a new bitmap from a string or from an array or list of strings. If you
want to use different characters you can:

    Image::Xbm->set( -setch => 'X', -unsetch => ' ' ) ;
    my $s = $p->new_from_string( "XXX", "X X", "XhX" ) ;

You can also specify a hotspot by making one of the characters a 'H' (set bit
hotspot) or 'h' (unset bit hotspot) -- you can use different characters by
setting C<-sethotch> and C<-unsethotch> respectively.

=head2 get()
    
    my $width = $i->get( -width ) ;

Get any of the object's attributes. 

See C<xy> and C<vec> to get/set bits of the image itself.

=head2 set()

    $i->set( -hotx => 120, -hoty => 32 ) ;

Set any of the object's attributes. Multiple attributes may be set in one go.
Except for C<-setch> and C<-unsetch> all attributes are object attributes;
some attributes are read-only.

See C<xy> and C<vec> to get/set bits of the image itself.

=head2 class attributes

    Image::Xbm->set( -setch => 'X' ) ;
    $i->set( -setch => '@', -unsetch => '*' ) ;

=over

=item C<-setch>

The character to print set bits as when using C<as_string>, default is '#'.
This is a class attribute accessible from the class or an object via C<get>
and C<set>.

=item C<-unsetch>

The character to print set bits as when using C<as_string>, default is '-'.
This is a class attribute accessible from the class or an object via C<get>
and C<set>.

=item C<-sethotch>

The character to print set bits as when using C<as_string>, default is 'H'.
This is a class attribute accessible from the class or an object via C<get>
and C<set>.

=item C<-unsethotch>

The character to print set bits as when using C<as_string>, default is 'h'.
This is a class attribute accessible from the class or an object via C<get>
and C<set>.

=back

=head2 xy()

    $i->xy( 4, 11, 1 ) ;      # Set the bit at point 4,11
    my $v = $i->xy( 9, 17 ) ; # Get the bit at point 9,17

Get/set bits using x, y coordinates; coordinates start at 0.

=head2 vec()

    $i->vec( 43, 0 ) ;      # Unset the bit at offset 43
    my $v = $i->vec( 87 ) ; # Get the bit at offset 87

Get/set bits using vector offsets; offsets start at 0.

=head2 load()

    $i->load ;
    $i->load( 'test.xbm' ) ;

Load the image whose name is given, or if none is given load the image whose
name is in the C<-file> attribute.

=head2 save()

    $i->save ;
    $i->save( 'test.xbm' ) ;

Save the image using the name given, or if none is given save the image using
the name in the C<-file> attribute. The image is saved in xbm format, e.g.

    #define test_width 6
    #define test_height 6
    static unsigned char test_bits[] = {
     0x1f, 0x07, 0x07, 0x09, 0x11, 0x20 } ;

=head2 is_equal()

    print "equal\n" if $i->is_equal( $j ) ;

Returns true (1) if the images are equal, false (0) otherwise. Note that
hotspots and filenames are ignored, so we compare width, height and the actual
bits only.

=head2 as_string()

    print $i->as_string ;

Returns the image as a string, e.g.

    #####-
    ###---
    ###---
    #--#--
    #---#-
    -----#

The characters used may be changed by C<set>ting the C<-setch> and C<-unsetch>
characters. If you give C<as_string> a parameter it will print out the hotspot
if present using C<-sethotch> or C<-unsethotch> as appropriate, e.g.

    print $n->as_string( 1 ) ;

    H##
    #-#
    ###

=head2 as_binstring()

    print $i->as_binstring ;

Returns the image as a string of 0's and 1's, e.g.

    1111101110001110001001001000100000010000

=head1 CHANGES

2000/04/30 

Created. 


=head1 AUTHOR

Mark Summerfield. I can be contacted as <summer@perlpress.com> -
please include the word 'xbm' in the subject line.

=head1 COPYRIGHT

Copyright (c) Mark Summerfield 2000. All Rights Reserved.

This module may be used/distributed/modified under the LGPL. 

=cut

