package Crypt::PK;

use strict;
use warnings;

use Carp;
use Crypt::Digest qw(digest_data);
use MIME::Base64 qw(decode_base64 encode_base64);
use Crypt::Mode::CBC;
use Crypt::Mode::CFB;
use Crypt::Mode::ECB;
use Crypt::Mode::OFB;
use Crypt::Cipher;
use Crypt::PRNG 'random_bytes';

sub _slurp_file {
  my $f = shift;
  croak "FATAL: non-existing file '$f'" unless -f $f;
  local $/ = undef;
  open FILE, "<", $f or croak "FATAL: couldn't open file: $!";
  binmode FILE;
  my $string = <FILE>;
  close FILE;
  return $string;
}

sub _name2mode {
  my $cipher_name = uc(shift);
  my %trans = ( 'DES-EDE3' => 'DES_EDE' );

  my ($cipher, undef, $klen, $mode) = $cipher_name =~ /^(AES|CAMELLIA|DES|DES-EDE3|SEED)(-(\d+))?-(CBC|CFB|ECB|OFB)$/i;
  croak "FATAL: unsupported cipher '$cipher_name'" unless $cipher && $mode;
  $cipher = $trans{$cipher} || $cipher;
  $klen = $klen ? int($klen/8) : Crypt::Cipher::min_keysize($cipher);
  my $ilen = Crypt::Cipher::blocksize($cipher);
  croak "FATAL: unsupported cipher '$cipher_name'" unless $klen && $ilen;

  return (Crypt::Mode::CBC->new($cipher), $klen, $ilen) if $mode eq 'CBC';
  return (Crypt::Mode::CFB->new($cipher), $klen, $ilen) if $mode eq 'CFB';
  return (Crypt::Mode::ECB->new($cipher), $klen, $ilen) if $mode eq 'ECB';
  return (Crypt::Mode::OFB->new($cipher), $klen, $ilen) if $mode eq 'OFB';
}

sub _password2key {
  my ($password, $klen, $iv, $hash) = @_;
  my $salt = substr($iv, 0, 8);
  my $key = '';
  while (length($key) < $klen) {
    $key .= digest_data($hash, $key . $password . $salt);
  }
  return substr($key, 0, $klen);
}

sub _pem_to_asn1 {
  my ($data, $password) = @_;

  my ($begin, $object, $headers, $content, $end) = $data =~ m/(-----BEGIN ([^\r\n\-]+KEY)-----)\r?\n(.*?\r?\n\r?\n)?(.+)(-----END [^\r\n\-]*-----)/s;

  return $content unless $content;
  $content = decode_base64($content);

  my ($ptype, $cipher_name, $iv_hex);
  for my $h (split /\n/, ($headers||'')) {
    my ($k, $v) = split /:\s*/, $h, 2;
    $ptype = $v if $k eq 'Proc-Type';
    ($cipher_name, $iv_hex) = $v =~ /^\s*(.*?)\s*,\s*([0-9a-fA-F]+)\s*$/ if $k eq 'DEK-Info';
  }

  if ($cipher_name && $iv_hex && $ptype && $ptype eq '4,ENCRYPTED') {
    croak "FATAL: encrypted PEM but no password provided" unless defined $password;
    my $iv = pack("H*", $iv_hex);
    my ($mode, $klen) = _name2mode($cipher_name);
    my $key = _password2key($password, $klen, $iv, 'MD5');
    return $mode->decrypt($content, $key, $iv);
  }

  return $content;
}

sub _asn1_to_pem {
  my ($data, $header_name, $password, $cipher_name) = @_;
  my $content = $data;
  my @headers;

  if ($password) {
    $cipher_name ||= 'AES-256-CBC';
    my ($mode, $klen, $ilen) = _name2mode($cipher_name);
    my $iv = random_bytes($ilen);
    my $key = _password2key($password, $klen, $iv, 'MD5');
    $content = $mode->encrypt($data, $key, $iv);
    push @headers, 'Proc-Type: 4,ENCRYPTED', "DEK-Info: ".uc($cipher_name).",".unpack("H*", $iv);
  }

  my $rv = "-----BEGIN $header_name-----\n";
  if (@headers) {
    $rv .= "$_\n" for @headers;
    $rv .= "\n";
  }
  my @l = encode_base64($content, "") =~ /.{1,64}/g;
  $rv .= join("\n", @l) . "\n";
  $rv .= "-----END $header_name-----\n";
}

1;

__END__

=head1 NAME

Crypt::PK - [internal only]

=cut