{ pkgs, ... }:
{
  time = "2026-08-16T17:01:50+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `programs.libreoffice`.

    LibreOffice is a comprehensive office productivity suite.
  '';
}
