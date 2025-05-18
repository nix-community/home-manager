{ pkgs, ... }:

{
  time = "2023-12-28T08:28:26+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.osmscout-server'.
  '';
}
