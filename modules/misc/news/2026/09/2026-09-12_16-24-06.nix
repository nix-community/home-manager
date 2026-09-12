{ config, pkgs, ... }:
{
  time = "2026-09-12T16:24:06+00:00";
  condition =
    pkgs.stdenv.hostPlatform.isDarwin
    && config.programs.firefox.enable
    && config.programs.firefox.package != null;
  message = ''
    On macOS 27 and later, Firefox builds not signed by Mozilla cannot access
    the traditional data directory. Set
    `programs.firefox.configPath = "Library/Application Support/org.nixos.firefox";`
    explicitly. Before changing `configPath`, quit Firefox and migrate your data from
    `~/Library/Application Support/Firefox` to
    `~/Library/Application Support/org.nixos.firefox`.
  '';
}
