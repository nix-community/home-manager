{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.jujutsu;
  packageVersion = lib.getVersion cfg.package;

  # jj v0.29+ deprecated support for "~/Library/Application Support" on Darwin.
  configDir =
    if pkgs.stdenv.isDarwin && !(lib.versionAtLeast packageVersion "0.29.0") then
      "Library/Application Support"
    else
      ".config";
in
{
  programs.jujutsu.enable = true;

  nmt.script = ''
    assertPathNotExists 'home-files/${configDir}/jj/config.toml'
  '';
}
