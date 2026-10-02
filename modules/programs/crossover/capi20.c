/*
 * Stub implementation of the CAPI 2.0 library (libcapi20.so.3).
 *
 * CrossOver ships Wine's capi2032.so with a hard DT_NEEDED on libcapi20.so.3,
 * the ISDN CAPI 2.0 API. No nixpkgs package provides it (ISDN CAPI hardware
 * is extinct), and autoPatchelf can never satisfy the dependency, so CrossOver
 * flags it as a missing 64-bit library. This stub exists only to provide the
 * SONAME and the entry points capi2032.so imports. Each call reports "CAPI
 * not installed", which is what a program gets when the real library is
 * absent; CAPI adapters no longer exist, so nothing can legitimately use it.
 */

#define CAPIERR_NOTINSTALLED 1001

unsigned capi20_register(
    unsigned maxLogicalConnection,
    unsigned maxBDataBlocks,
    unsigned maxBDataLen,
    unsigned maxB3Connection,
    unsigned maxB3Blocks,
    unsigned maxB3Len,
    unsigned maxNCCI,
    unsigned maxController)
{
    return CAPIERR_NOTINSTALLED;
}

unsigned capi20_release(unsigned appl)
{
    return CAPIERR_NOTINSTALLED;
}

unsigned capi20_put_message(unsigned appl, void *message)
{
    return CAPIERR_NOTINSTALLED;
}

unsigned capi20_get_message(unsigned appl, void *message)
{
    return CAPIERR_NOTINSTALLED;
}

unsigned capi20_release_message(unsigned appl, unsigned message)
{
    return CAPIERR_NOTINSTALLED;
}

unsigned capi20_waitformessage(unsigned appl, void *message)
{
    return CAPIERR_NOTINSTALLED;
}

unsigned capi20_get_manufacturer(unsigned controller, char *buf)
{
    if (buf)
        buf[0] = '\0';
    return CAPIERR_NOTINSTALLED;
}

unsigned capi20_get_version(unsigned controller, unsigned *version)
{
    return CAPIERR_NOTINSTALLED;
}

unsigned capi20_get_serial_number(unsigned controller, char *buf)
{
    if (buf)
        buf[0] = '\0';
    return CAPIERR_NOTINSTALLED;
}

unsigned capi20_isinstalled(void)
{
    return CAPIERR_NOTINSTALLED;
}

unsigned capi20_get_profile(unsigned controller, void *profile)
{
    return CAPIERR_NOTINSTALLED;
}
