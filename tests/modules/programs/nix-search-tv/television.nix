{ lib, pkgs, ... }:
{
  programs.television.enable = true;

  programs.nix-search-tv.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/television/cable/nix-search-tv.toml
    assertFileContent home-files/.config/television/cable/nix-search-tv.toml \
      ${pkgs.writeText "settings-expected" ''
        [metadata]
        description = "Search nix options and packages"
        name = "nix-search-tv"

        [preview]
        command = "${lib.getExe pkgs.nix-search-tv} preview {}"

        [source]
        command = "${lib.getExe pkgs.nix-search-tv} print"
      ''}
  '';
}
