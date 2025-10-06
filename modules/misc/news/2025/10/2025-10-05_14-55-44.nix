{ pkgs, ... }:

{
  time = "2025-10-05T17:55:44+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `programs.am2rlauncher`

    AM2RLauncher is a front-end application that simplifies installing the
    latest AM2R-Community-Updates, creating APKs for Android use, as well as
    Mods for AM2R. It supports Windows (x86/x64) as well as Linux (x64).
  '';
}
