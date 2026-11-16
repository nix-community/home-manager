{ pkgs, ... }:
{
  time = "2026-08-29T08:11:49+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.impala'

    TUI for managing wifi on Linux, with iwd as the wifi backend.
    See <https://github.com/pythops/impala> for more.
  '';
}
