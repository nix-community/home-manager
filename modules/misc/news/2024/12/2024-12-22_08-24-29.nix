{ pkgs, ... }:

{
  time = "2024-12-22T08:24:29+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.cavalier'.

    Cavalier is a GUI wrapper around the Cava audio visualizer.
  '';
}
