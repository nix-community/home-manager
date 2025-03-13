{ pkgs, config, ... }:

{
  programs.nushell.enable = true;
  programs.direnv.enable = true;

  nmt.script = let
    configFile = if pkgs.stdenv.isDarwin && !config.xdg.enable then
      "home-files/Library/Application Support/nushell/config.nu"
    else
      "home-files/.config/nushell/config.nu";
  in ''
    assertFileExists "${configFile}"
    assertFileRegex "${configFile}" '@direnv@/bin/direnv export json'
  '';
}
