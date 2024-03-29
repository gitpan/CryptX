/* LibTomCrypt, modular cryptographic library -- Tom St Denis
 *
 * LibTomCrypt is a library that provides various cryptographic
 * algorithms in a highly modular and flexible manner.
 *
 * The library is free for all purposes without any express
 * guarantee it works.
 *
 */

/* Implements ECC over Z/pZ for curve y^2 = x^3 + a*x + b
 *
 */

#include "tomcrypt.h"

#ifdef LTC_MECC

int ecc_dp_init(ltc_ecc_set_type *dp)
{
  if (dp == NULL) return CRYPT_INVALID_ARG;

  dp->name  = NULL;
  dp->prime = NULL;
  dp->A     = NULL;
  dp->B     = NULL;
  dp->order = NULL;
  dp->Gx    = NULL;
  dp->Gy    = NULL;
  dp->cofactor = 0;

  return CRYPT_OK;
}

#endif
