package Crypt::Digest::RIPEMD128;

### BEWARE - GENERATED FILE, DO NOT EDIT MANUALLY!

use strict;
use warnings;

use Exporter 'import';
our %EXPORT_TAGS = ( all => [qw( ripemd128 ripemd128_hex ripemd128_base64 ripemd128_file ripemd128_file_hex ripemd128_file_base64 )] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

use CryptX;
use base 'Crypt::Digest';

sub hashsize { Crypt::Digest::hashsize(__PACKAGE__) }

sub ripemd128             { __PACKAGE__->new->add(@_)->digest }
sub ripemd128_hex         { __PACKAGE__->new->add(@_)->hexdigest }
sub ripemd128_base64      { __PACKAGE__->new->add(@_)->b64digest }

sub ripemd128_file        { __PACKAGE__->new->addfile(@_)->digest }
sub ripemd128_file_hex    { __PACKAGE__->new->addfile(@_)->hexdigest }
sub ripemd128_file_base64 { __PACKAGE__->new->addfile(@_)->b64digest }

1;

=pod

=head1 NAME

Crypt::Digest::RIPEMD128 - Hash function RIPEMD-128 [size: 128 bits]

=head1 SYNOPSIS

   ### Functional interface:
   use Crypt::Digest::RIPEMD128 qw( ripemd128 ripemd128_hex ripemd128_base64 ripemd128_file ripemd128_file_hex ripemd128_file_base64 );

   # calculate digest from string/buffer
   $ripemd128_raw = ripemd128('data string');
   $ripemd128_hex = ripemd128_hex('data string');
   $ripemd128_b64 = ripemd128_base64('data string');
   # calculate digest from file
   $ripemd128_raw = ripemd128_file('filename.dat');
   $ripemd128_hex = ripemd128_file_hex('filename.dat');
   $ripemd128_b64 = ripemd128_file_base64('filename.dat');
   # calculate digest from filehandle
   $ripemd128_raw = ripemd128_file(*FILEHANDLE);
   $ripemd128_hex = ripemd128_file_hex(*FILEHANDLE);
   $ripemd128_b64 = ripemd128_file_base64(*FILEHANDLE);

   ### OO interface:
   use Crypt::Digest::RIPEMD128;

   $d = Crypt::Digest::RIPEMD128->new;
   $d->add('any data');
   $d->addfile('filename.dat');
   $d->addfile(*FILEHANDLE);
   $result_raw = $d->digest;    # raw bytes
   $result_hex = $d->hexdigest; # hexadecimal form
   $result_b64 = $d->b64digest; # Base64 form

=head1 DESCRIPTION

Provides an interface to the RIPEMD128 digest algorithm.

=head1 EXPORT

Nothing is exported by default.

You can export selected functions:

  use Crypt::Digest::RIPEMD128 qw(ripemd128 ripemd128_hex ripemd128_base64 ripemd128_file ripemd128_file_hex ripemd128_file_base64);

Or all of them at once:

  use Crypt::Digest::RIPEMD128 ':all';

=head1 FUNCTIONS

=head2 ripemd128

Logically joins all arguments into a single string, and returns its RIPEMD128 digest encoded as a binary string.

 $ripemd128_raw = ripemd128('data string');
 #or
 $ripemd128_raw = ripemd128('any data', 'more data', 'even more data');

=head2 ripemd128_hex

Logically joins all arguments into a single string, and returns its RIPEMD128 digest encoded as a hexadecimal string.

 $ripemd128_hex = ripemd128_hex('data string');
 #or
 $ripemd128_hex = ripemd128('any data', 'more data', 'even more data');

=head2 ripemd128_base64

Logically joins all arguments into a single string, and returns its RIPEMD128 digest encoded as a Base64 string, B<with> trailing '=' padding.

 $ripemd128_base64 = ripemd128_base64('data string');
 #or
 $ripemd128_base64 = ripemd128('any data', 'more data', 'even more data');

=head2 ripemd128_file

Reads file (defined by filename or filehandle) content, and returns its RIPEMD128 digest encoded as a binary string.

 $ripemd128_raw = ripemd128_file('filename.dat');
 #or
 $ripemd128_raw = ripemd128_file(*FILEHANDLE);

=head2 ripemd128_file_hex

Reads file (defined by filename or filehandle) content, and returns its RIPEMD128 digest encoded as a hexadecimal string.

 $ripemd128_hex = ripemd128_file_hex('filename.dat');
 #or
 $ripemd128_hex = ripemd128_file_hex(*FILEHANDLE);

B<BEWARE:> You have to make sure that the filehandle is in binary mode before you pass it as argument to the addfile() method.

=head2 ripemd128_file_base64

Reads file (defined by filename or filehandle) content, and returns its RIPEMD128 digest encoded as a Base64 string, B<with> trailing '=' padding.

 $ripemd128_base64 = ripemd128_file_base64('filename.dat');
 #or
 $ripemd128_base64 = ripemd128_file_base64(*FILEHANDLE);

=head1 METHODS

The OO interface provides the same set of functions as L<Crypt::Digest>.

=head2 new

 $d = Crypt::Digest::RIPEMD128->new();

=head2 clone

 $d->clone();

=head2 reset

 $d->reset();

=head2 add

 $d->add('any data');
 #or
 $d->add('any data', 'more data', 'even more data');

=head2 addfile

 $d->addfile('filename.dat');
 #or
 $d->addfile(*FILEHANDLE);

=head2 add_bits

 $d->addfile('filename.dat');
 #or
 $d->addfile(*FILEHANDLE);

=head2 hashsize

 $d->hashsize;
 #or
 Crypt::Digest::RIPEMD128->hashsize();
 #or
 Crypt::Digest::RIPEMD128::hashsize();

=head2 digest

 $result_raw = $d->digest();

=head2 hexdigest

 $result_hex = $d->hexdigest();

=head2 b64digest

 $result_base64 = $d->b64digest();

=head1 SEE ALSO

=over 4

=item L<CryptX|CryptX>, L<Crypt::Digest|Crypt::Digest>

=item L<http://en.wikipedia.org/wiki/RIPEMD|http://en.wikipedia.org/wiki/RIPEMD>

=back

=cut

__END__