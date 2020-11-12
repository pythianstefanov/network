#!/bin/sh
## Roll out script for October 2018 *.ihotelier.com profile swaps on LDC Prod F5.
##
./swap-profiles.sh profile_wildcard.ihotelier.com_NewSSLCert_NO_RC4_NO_3DES profile_wildcard.ihotelier.com_exp_09_06_2020_NO_RC4_NO_3DES
./swap-profiles.sh profile_wildcard.ihotelier.com_NewSSLCert_NO_RC4_NO_3DES_No_Tls1.0 profile_wildcard.ihotelier.com_exp_09_06_2020_NO_RC4_NO_3DES_No_Tls1.0
./swap-profiles.sh profile_wildcard.ihotelier.com_RestrictCiphers_WithoutRC4_NewSSLCert profile_wildcard.ihotelier.com_exp_09_06_2020_RestrictCiphers_WithoutRC4
./swap-profiles.sh profile_wildcard.ihotelier.com_RestrictCiphers_WithoutRC4_NewSSLCert_No_Tls1.0 profile_wildcard.ihotelier.com_exp_09_06_2020_RestrictCiphers_WithoutRC4_No_Tls1.0
./swap-profiles.sh profile_imanager-ebs.travelclick.net profile_wildcard.ihotelier.com_exp_09_06_2020_RestrictCiphers_WithoutRC4
