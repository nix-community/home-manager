{ pkgs, ... }:

{
  time = "2022-10-18T08:07:43+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.looking-glass-client'.
  '';
}
