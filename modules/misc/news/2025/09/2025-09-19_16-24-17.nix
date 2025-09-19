{ pkgs, ... }:

{
  time = "2025-09-19T14:24:17+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `programs.wleave`

    A Rust/GTK4 port of `programs.wlogout` with improvements.
  '';
}
