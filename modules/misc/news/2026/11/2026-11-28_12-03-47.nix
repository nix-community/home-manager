{ pkgs, ... }:

{
  time = "2026-11-28T04:03:47+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new module is available: `programs.altTab`.

    It configures AltTab's package, Space filter, and activation shortcut
    on macOS.
  '';
}
