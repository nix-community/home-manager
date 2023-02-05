{ pkgs, ... }:

{
  programs.nushell.enable = true;
  programs.direnv.enable = true;

  test.stubs.nushell = { };

  nmt.script = let
    configFile = if pkgs.stdenv.isDarwin then
      "home-files/Library/Application Support/nushell/config.nu"
    else
      "home-files/.config/nushell/config.nu";
  in ''
    assertFileExists "${configFile}"
    assertFileRegex "${configFile}" \
      'let direnv = (/nix/store/.*direnv.*/bin/direnv export json | from json)'
  '';
}
