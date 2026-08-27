{ config, pkgs, ... }:
{
  time = "2026-08-27T23:50:03+00:00";
  condition =
    pkgs.stdenv.hostPlatform.isDarwin
    && config.programs.firefox.enable
    && config.programs.firefox.package != null;
  message = ''
    On Darwin, the default value of `programs.firefox.configPath` has changed
    for `home.stateVersion` 26.11 and later from
    `Library/Application Support/Firefox` to
    `Library/Application Support/org.nixos.firefox`.

    This is needed on macOS 27 and later, where Firefox builds not signed by
    Mozilla cannot access the traditional data directory. Before updating
    `home.stateVersion`, quit Firefox and migrate your Firefox data from
    `~/Library/Application Support/Firefox` to
    `~/Library/Application Support/org.nixos.firefox`.
  '';
}
