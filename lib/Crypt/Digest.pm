package Crypt::Digest;

use strict;
use warnings;

use Exporter 'import';
our %EXPORT_TAGS = ( all => [qw( digest_data digest_data_hex digest_data_b64 digest_data_b64u digest_file digest_file_hex digest_file_b64 digest_file_b64u )] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

use Carp;
$Carp::Internal{(__PACKAGE__)}++;
use CryptX;

### the following methods/functions are implemented in XS:
# - _new
# - _hashsize
# - _hashsize_by_name (function, not method)
# - clone
# - reset
# - digest
# - hexdigest
# - b64digest
# - add
# - DESTROY

sub _trans_digest_name {
  my $name = shift;
  my %trans = (
    CHAES     => 'chc_hash',
    RIPEMD128 => 'rmd128',
    RIPEMD160 => 'rmd160',
    RIPEMD256 => 'rmd256',
    RIPEMD320 => 'rmd320',
    TIGER192  => 'tiger',
  );
  $name =~ s/^Crypt::Digest:://i;
  return $trans{uc($name)} if defined $trans{uc($name)};
  return lc($name);
}

### METHODS

sub new {
  my $pkg = shift;
  unshift @_, ($pkg eq 'Crypt::Digest' ? _trans_digest_name(shift) : _trans_digest_name($pkg));
  ###return _new(@_);
  goto \&_new; # keep the real caller for croak()
}

sub hashsize {
  return unless defined $_[0];

  if (ref $_[0]) {
    ###return _hashsize(@_);
    goto \&_hashsize if ref $_[0];        # keep the real caller for croak()
  }
  else {
    my $pkg = shift;
    unshift @_, ($pkg eq 'Crypt::Digest' ? _trans_digest_name(shift) : _trans_digest_name($pkg));
    ###return _hashsize_by_name(@_);
    goto \&_hashsize_by_name;             # keep the real caller for croak()
  }
}

sub addfile {
  my ($self, $file) = @_;

  my $handle;
  if (ref(\$file) eq 'SCALAR') {        #filename
    open($handle, "<", $file) || croak "FATAL: cannot open '$file': $!";
    binmode($handle);
  }
  else {                                #handle
    $handle = $file
  }
  croak "FATAL: invalid handle" unless defined $handle;

  my $n;
  my $buf = "";
  while (($n = read($handle, $buf, 32*1024))) {
    $self->add($buf)
  }
  croak "FATAL: read failed: $!" unless defined $n;

  return $self;
}

sub CLONE_SKIP { 1 } # prevent cloning

### FUNCTIONS

sub digest_data        { my $rv = eval {Crypt::Digest->new(shift)->add(@_)->digest}; _croak($@); $rv }
sub digest_data_hex    { my $rv = eval {Crypt::Digest->new(shift)->add(@_)->hexdigest}; _croak($@); $rv }
sub digest_data_b64    { my $rv = eval {Crypt::Digest->new(shift)->add(@_)->b64digest}; _croak($@); $rv }
sub digest_data_b64u   { my $rv = eval {Crypt::Digest->new(shift)->add(@_)->b64udigest}; _croak($@); $rv }

sub digest_file        { my $rv = eval {Crypt::Digest->new(shift)->addfile(@_)->digest}; _croak($@); $rv }
sub digest_file_hex    { my $rv = eval {Crypt::Digest->new(shift)->addfile(@_)->hexdigest}; _croak($@); $rv }
sub digest_file_b64    { my $rv = eval {Crypt::Digest->new(shift)->addfile(@_)->b64digest}; _croak($@); $rv }
sub digest_file_b64u   { my $rv = eval {Crypt::Digest->new(shift)->addfile(@_)->b64udigest}; _croak($@); $rv }

sub _croak { #XXX-FIXME ugly hack for reporting real caller from XS croaks
   if ($_[0]) {
     $_[0] =~ s/ at .*?\.pm line \d+.[\n\r]*$//g;
     croak $_[0];
   }
}

1;

=pod

=head1 NAME

Crypt::Digest - Generic interface to hash/digest functions

=head1 SYNOPSIS

   ### Functional interface:
   use Crypt::Digest qw( digest_data digest_data_hex digest_data_b64 digest_data_b64u
                         digest_file digest_file_hex digest_file_b64 digest_file_b64u );

   # calculate digest from string/buffer
   $digest_raw  = digest_data('SHA1', 'data string');
   $digest_hex  = digest_data_hex('SHA1', 'data string');
   $digest_b64  = digest_data_b64('SHA1', 'data string');
   $digest_b64u = digest_data_b64u('SHA1', 'data string');
   # calculate digest from file
   $digest_raw  = digest_file('SHA1', 'filename.dat');
   $digest_hex  = digest_file_hex('SHA1', 'filename.dat');
   $digest_b64  = digest_file_b64('SHA1', 'filename.dat');
   $digest_b64u = digest_file_b64u('SHA1', 'filename.dat');
   # calculate digest from filehandle
   $digest_raw  = digest_file('SHA1', *FILEHANDLE);
   $digest_hex  = digest_file_hex('SHA1', *FILEHANDLE);
   $digest_b64  = digest_file_b64('SHA1', *FILEHANDLE);
   $digest_b64u = digest_file_b64u('SHA1', *FILEHANDLE);

   ### OO interface:
   use Crypt::Digest;

   $d = Crypt::Digest->new('SHA1');
   $d->add('any data');
   $d->addfile('filename.dat');
   $d->addfile(*FILEHANDLE);
   $result_raw  = $d->digest;     # raw bytes
   $result_hex  = $d->hexdigest;  # hexadecimal form
   $result_b64  = $d->b64digest;  # Base64 form
   $result_b64u = $d->b64udigest; # Base64 URL Safe form

=head1 DESCRIPTION

Provides an interface to various hash/digest algorithms.

=head1 EXPORT

Nothing is exported by default.

You can export selected functions:

  use Crypt::Digest qw( digest_data digest_data_hex digest_data_b64 digest_data_b64u
                        digest_file digest_file_hex digest_file_b64 digest_file_b64u );

Or all of them at once:

  use Crypt::Digest ':all';

=head1 FUNCTIONS

Please note that all functions take as its first argument the algoritm name, supported values are:

 'CHAES', 'MD2', 'MD4', 'MD5', 'RIPEMD128', 'RIPEMD160',
 'RIPEMD256', 'RIPEMD320', 'SHA1', 'SHA224', 'SHA256',
 'SHA384', 'SHA512', 'Tiger192', 'Whirlpool'

 (simply any <FUNCNAME> for which there is Crypt::Digest::<FUNCNAME> module)

=head2 digest_data

Logically joins all arguments into a single string, and returns its SHA1 digest encoded as a binary string.

 $digest_raw = digest_data('SHA1', 'data string');
 #or
 $digest_raw = digest_data('SHA1', 'any data', 'more data', 'even more data');

=head2 digest_data_hex

Logically joins all arguments into a single string, and returns its SHA1 digest encoded as a hexadecimal string.

 $digest_hex = digest_data_hex('SHA1', 'data string');
 #or
 $digest_hex = digest_data_hex('SHA1', 'any data', 'more data', 'even more data');

=head2 digest_data_b64

Logically joins all arguments into a single string, and returns its SHA1 digest encoded as a Base64 string, B<with> trailing '=' padding.

 $digest_b64 = digest_data_b64('SHA1', 'data string');
 #or
 $digest_b64 = digest_data_b64('SHA1', 'any data', 'more data', 'even more data');

=head2 digest_data_b64u

Logically joins all arguments into a single string, and returns its SHA1 digest encoded as a Base64 URL Safe string (see RFC 4648 section 5).

 $digest_b64url = digest_data_b64u('SHA1', 'data string');
 #or
 $digest_b64url = digest_data_b64u('SHA1', 'any data', 'more data', 'even more data');

=head2 digest_file

Reads file (defined by filename or filehandle) content, and returns its digest encoded as a binary string.

 $digest_raw = digest_file('SHA1', 'filename.dat');
 #or
 $digest_raw = digest_file('SHA1', *FILEHANDLE);

=head2 digest_file_hex

Reads file (defined by filename or filehandle) content, and returns its digest encoded as a hexadecimal string.

 $digest_hex = digest_file_hex('SHA1', 'filename.dat');
 #or
 $digest_hex = digest_file_hex('SHA1', *FILEHANDLE);

B<BEWARE:> You have to make sure that the filehandle is in binary mode before you pass it as argument to the addfile() method.

=head2 digest_file_b64

Reads file (defined by filename or filehandle) content, and returns its digest encoded as a Base64 string, B<with> trailing '=' padding.

 $digest_b64 = digest_file_b64('SHA1', 'filename.dat');
 #or
 $digest_b64 = digest_file_b64('SHA1', *FILEHANDLE);

=head2 digest_file_b64u

Reads file (defined by filename or filehandle) content, and returns its digest encoded as a Base64 URL Safe string (see RFC 4648 section 5).

 $digest_b64url = digest_file_b64u('SHA1', 'filename.dat');
 #or
 $digest_b64url = digest_file_b64u('SHA1', *FILEHANDLE);

=head1 METHODS

=head2 new

Constructor, returns a reference to the digest object.

 $d = Crypt::Digest->new($name);
 # $name could be: 'CHAES', 'MD2', 'MD4', 'MD5', 'RIPEMD128', 'RIPEMD160',
 #                 'RIPEMD256', 'RIPEMD320', 'SHA1', 'SHA224', 'SHA256',
 #                 'SHA384', 'SHA512', 'Tiger192', 'Whirlpool'
 #
 # simply any <FUNCNAME> for which there is Crypt::Digest::<FUNCNAME> module

=head2 clone

Creates a copy of the digest object state and returns a reference to the copy.

 $d->clone();

=head2 reset

Reinitialize the digest object state and returns a reference to the digest object.

 $d->reset();

=head2 add

All arguments are appended to the message we calculate digest for.
The return value is the digest object itself.

 $d->add('any data');
 #or
 $d->add('any data', 'more data', 'even more data');

Note that all the following cases are equivalent:

 # case 1
 $d->add('aa', 'bb', 'cc');

 # case 2
 $d->add('aa');
 $d->add('bb');
 $d->add('cc');

 # case 3
 $d->add('aabbcc');

 # case 4
 $d->add('aa')->add('bb')->add('cc');

=head2 addfile

The content of the file (or filehandle) is appended to the message we calculate digest for.
The return value is the digest object itself.

 $d->addfile('filename.dat');
 #or
 $d->addfile(*FILEHANDLE);

B<BEWARE:> You have to make sure that the filehandle is in binary mode before you pass it as argument to the addfile() method.

=head2 add_bits

This method is available mostly for compatibility with other Digest::SOMETHING modules on CPAN, you are very unlikely to need it.
The return value is the digest object itself.

 $d->add_bits($bit_string);   # e.g. $d->add_bits("111100001010");
 #or
 $d->add_bits($data, $nbits); # e.g. $d->add_bits("\xF0\xA0", 16);

B<BEWARE:> It is not possible to add bits that are not a multiple of 8.

=head2 hashsize

Returns the length of calculated digest in bytes (e.g. 32 for SHA-256).

 $d->hashsize;
 #or
 Crypt::Digest->hashsize('SHA1');
 #or
 Crypt::Digest::hashsize('SHA1');

=head2 digest

Returns the binary digest (raw bytes).

 $result_raw = $d->digest();

=head2 hexdigest

Returns the digest encoded as a hexadecimal string.

 $result_hex = $d->hexdigest();

=head2 b64digest

Returns the digest encoded as a Base64 string, B<with> trailing '=' padding (B<BEWARE:> this padding
style might differ from other Digest::SOMETHING modules on CPAN).

 $result_b64 = $d->b64digest();

=head2 b64udigest

Returns the digest encoded as a Base64 URL Safe string (see RFC 4648 section 5).

 $result_b64url = $d->b64udigest();

=head1 SEE ALSO

=over

=item * L<CryptX|CryptX>

=item * L<Crypt::Digest|Crypt::Digest> tries to be compatible with L<Digest|Digest> interface.

=item * Check subclasses like L<Crypt::Digest::SHA1|Crypt::Digest::SHA1>, L<Crypt::Digest::MD5|Crypt::Digest::MD5>, ...

=back

=cut

__END__