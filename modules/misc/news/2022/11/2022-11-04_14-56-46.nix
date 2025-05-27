{ pkgs, ... }:

{
  time = "2022-11-04T14:56:46+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.thunderbird'.
  '';
}
