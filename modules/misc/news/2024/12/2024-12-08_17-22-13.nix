{ config, lib, ... }:

{
  time = "2024-12-08T17:22:13+00:00";
  condition =
    let
      usingMbsync = lib.any (a: a.enable && a.mbsync.enable) (
        lib.attrValues config.accounts.email.accounts
      );
    in
    usingMbsync;
  message = ''
    isync/mbsync 1.5.0 has changed several things.

    isync gained support for using $XDG_CONFIG_HOME, and now places
    its config file in '$XDG_CONFIG_HOME/isyncrc'.

    isync changed the configuration options SSLType and SSLVersion to
    TLSType and TLSVersion respectively.

    All instances of
    'accounts.email.accounts.<account-name>.mbsync.extraConfig.account'
    that use 'SSLType' or 'SSLVersion' should be replaced with 'TLSType'
    or 'TLSVersion', respectively.

    TLSType options are unchanged.

    TLSVersions has a new syntax, requiring a change to the Nix syntax.
    Old Syntax: SSLVersions = [ "TLSv1.3" "TLSv1.2" ];
    New Syntax: TLSVersions = [ "+1.3" "+1.2" "-1.1" ];
    NOTE: The minus symbol means to NOT use that particular TLS version.
  '';
}
