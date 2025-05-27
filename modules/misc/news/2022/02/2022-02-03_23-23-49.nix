{ pkgs, ... }:

{
  time = "2022-02-03T23:23:49+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.twmn'.
  '';
}
