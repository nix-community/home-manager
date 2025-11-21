{ pkgs, ... }:

{
  time = "2025-01-01T15:31:15+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    The 'systemd.user.startServices' option now defaults to 'true',
    meaning that services will automatically be restarted as needed when
    activating a configuration.

    Further, the "legacy" alternative has been removed and will now result
    in an evaluation error if used.

    The "suggest" alternative will remain for a while longer but may also
    be deprecated for removal in the future.
  '';
}
