{ config, pkgs, ... }:
let
  requiresManagedBrowserPackage =
    browserCfg:
    browserCfg.globalExtensions != [ ]
    && browserCfg.package == null
    && (!pkgs.stdenv.hostPlatform.isDarwin || browserCfg.darwinDefaultsId == null);
in
{
  time = "2026-06-18T17:40:40+00:00";
  condition =
    requiresManagedBrowserPackage config.programs.firefox
    || requiresManagedBrowserPackage config.programs.floorp
    || requiresManagedBrowserPackage config.programs.librewolf;
  message = ''
    The `programs.firefox.globalExtensions`,
    `programs.floorp.globalExtensions`, and
    `programs.librewolf.globalExtensions` options now assert that the browser
    package is managed by Home Manager. On Darwin, setting
    `programs.<browser>.darwinDefaultsId` also satisfies this requirement.

    If you used `globalExtensions` with `package = null`, set `package` to a
    non-null browser package or switch back to
    `profiles.<name>.extensions.packages`.
  '';
}
