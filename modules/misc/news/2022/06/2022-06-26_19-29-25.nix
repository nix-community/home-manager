{ pkgs, ... }:

{
  time = "2022-06-26T19:29:25+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.sctd'.
  '';
}
