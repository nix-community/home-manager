{ pkgs, ... }:
{
  time = "2026-08-04T16:16:25+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new module is availble for darwin: `programs.rift-wm'.
  '';
}
