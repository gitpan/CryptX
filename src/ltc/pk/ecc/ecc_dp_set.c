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

int ecc_dp_set(ltc_ecc_set_type *dp, char *ch_prime, char *ch_A, char *ch_B, char *ch_order, char *ch_Gx, char *ch_Gy, unsigned long cofactor, char *ch_name)
{
  unsigned long l_name, l_prime, l_A, l_B, l_order, l_Gx, l_Gy;
  
  if (!dp || !ch_prime || !ch_A || !ch_B || !ch_order || !ch_Gx || !ch_Gy || cofactor==0) return CRYPT_INVALID_ARG;
  
  l_name  = (unsigned long)strlen(ch_name);
  l_prime = (unsigned long)strlen(ch_prime);
  l_A     = (unsigned long)strlen(ch_A);
  l_B     = (unsigned long)strlen(ch_B);
  l_order = (unsigned long)strlen(ch_order);
  l_Gx    = (unsigned long)strlen(ch_Gx);
  l_Gy    = (unsigned long)strlen(ch_Gy);
       
  dp->cofactor = cofactor;
  
  { /* calculate size */
    void *p_num;
    mp_init(&p_num);
    mp_read_radix(p_num, ch_prime, 16);
    dp->size = mp_unsigned_bin_size(p_num);
    mp_clear(p_num);
  }

  if (dp->name  != NULL) { XFREE(dp->name ); dp->name  = NULL; }
  if (dp->prime != NULL) { XFREE(dp->prime); dp->prime = NULL; }
  if (dp->A     != NULL) { XFREE(dp->A    ); dp->A     = NULL; }
  if (dp->B     != NULL) { XFREE(dp->B    ); dp->B     = NULL; }
  if (dp->order != NULL) { XFREE(dp->order); dp->order = NULL; }
  if (dp->Gx    != NULL) { XFREE(dp->Gx   ); dp->Gx    = NULL; }
  if (dp->Gy    != NULL) { XFREE(dp->Gy   ); dp->Gy    = NULL; }
 
  dp->name  = XMALLOC(1+l_name);  strncpy(dp->name,  ch_name,  1+l_name);
  dp->prime = XMALLOC(1+l_prime); strncpy(dp->prime, ch_prime, 1+l_prime);
  dp->A     = XMALLOC(1+l_A);     strncpy(dp->A,     ch_A,     1+l_A);
  dp->B     = XMALLOC(1+l_B);     strncpy(dp->B,     ch_B,     1+l_B);
  dp->order = XMALLOC(1+l_order); strncpy(dp->order, ch_order, 1+l_order);
  dp->Gx    = XMALLOC(1+l_Gx);    strncpy(dp->Gx,    ch_Gx,    1+l_Gx);
  dp->Gy    = XMALLOC(1+l_Gy);    strncpy(dp->Gy,    ch_Gy,    1+l_Gy);
  
  return CRYPT_OK;
}

#endif
