package Crypt::Mac::OMAC;

### BEWARE - GENERATED FILE, DO NOT EDIT MANUALLY!

use strict;
use warnings;

use Exporter 'import';
our %EXPORT_TAGS = ( all => [qw( omac omac_hex omac_b64 )] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

use CryptX;
use base 'Crypt::Mac';

use Crypt::Cipher;

sub new { my $class = shift; _new(Crypt::Cipher::_trans_cipher_name(shift), @_) }
sub omac { Crypt::Mac::OMAC->new(shift, shift)->add(@_)->mac }
sub omac_hex { Crypt::Mac::OMAC->new(shift, shift)->add(@_)->hexmac }
sub omac_b64 { Crypt::Mac::OMAC->new(shift, shift)->add(@_)->b64mac }

1;

=pod

=head1 NAME

Crypt::Mac::OMAC - Message authentication code OMAC

=head1 SYNOPSIS

   ### Functional interface:
   use Crypt::Mac::OMAC qw( omac omac_hex );

   # calculate MAC from string/buffer
   $omac_raw = omac($cipher_name, $key, 'data string');
   $omac_hex = omac_hex($cipher_name, $key, 'data string');
   $omac_b64 = omac_b64($cipher_name, $key, 'data string');

   ### OO interface:
   use Crypt::Mac::OMAC;

   $d = Crypt::Mac::OMAC->new($cipher_name, $key);
   $d->add('any data');
   $d->addfile('filename.dat');
   $d->addfile(*FILEHANDLE);
   $result_raw = $d->mac;    # raw bytes
   $result_hex = $d->hexmac; # hexadecimal form
   $result_b64 = $d->b64mac; # Base64 form

=head1 DESCRIPTION

Provides an interface to the OMAC message authentication code (MAC) algorithm.

=head1 EXPORT

Nothing is exported by default.

You can export selected functions:

  use Crypt::Mac::OMAC qw(omac omac_hex );

Or all of them at once:

  use Crypt::Mac::OMAC ':all';

=head1 FUNCTIONS

=head2 omac

Logically joins all arguments into a single string, and returns its OMAC message authentication code encoded as a binary string.

 $omac_raw = omac($cipher_name, $key, 'data string');
 #or
 $omac_raw = omac($cipher_name, $key, 'any data', 'more data', 'even more data');

=head2 omac_hex

Logically joins all arguments into a single string, and returns its OMAC message authentication code encoded as a hexadecimal string.

 $omac_hex = omac($cipher_name, $key, 'data string');
 #or
 $omac_hex = omac($cipher_name, $key, 'any data', 'more data', 'even more data');

=head2 omac_b64

Logically joins all arguments into a single string, and returns its OMAC message authentication code encoded as a BASE64 string.

 $omac_b64 = omac($cipher_name, $key, 'data string');
 #or
 $omac_b64 = omac($cipher_name, $key, 'any data', 'more data', 'even more data');

=head1 METHODS

The OO interface provides the same set of functions as L<Crypt::Mac>.

=head2 new

 $d = Crypt::Mac::OMAC->new($cipher_name, $key);

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

=head2 mac

 $result_raw = $d->mac();

=head2 hexmac

 $result_hex = $d->hexmac();

=head2 b64mac

 $result_base64 = $d->b64mac();

=head1 SEE ALSO

=over 4

=item L<CryptX|CryptX>, L<Crypt::Mac|Crypt::Mac>

=back

=cut

__END__