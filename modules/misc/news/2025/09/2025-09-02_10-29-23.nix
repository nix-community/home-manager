{ pkgs, ... }:

{
  time = "2025-09-02T13:29:23+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `programs.swappy`

    Swappy is a Wayland native snapshot and editor tool,
    inspired by Snappy on macOS. Works great with grim,
    slurp and sway. But can easily work with other screen
    copy tools that can output a final image to stdout.
  '';
}
