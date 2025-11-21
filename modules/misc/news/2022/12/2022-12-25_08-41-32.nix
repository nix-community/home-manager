{ pkgs, ... }:

{
  time = "2022-12-25T08:41:32+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.cachix-agent'.
  '';
}
