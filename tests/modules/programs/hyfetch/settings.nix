{
  xdgEnable ? true,
  configDir ? ".config",
}:
{ config, pkgs, ... }:
let
  darwinConfigFile = "Library/Application Support/hyfetch.json";
  xdgConfigFile = "${configDir}/hyfetch.json";
  expectedConfigFile = if pkgs.stdenv.hostPlatform.isDarwin then darwinConfigFile else xdgConfigFile;
  unexpectedConfigFile =
    if pkgs.stdenv.hostPlatform.isDarwin then xdgConfigFile else darwinConfigFile;
in
{
  xdg = {
    enable = xdgEnable;
    configHome = "${config.home.homeDirectory}/${configDir}";
  };

  programs.hyfetch = {
    enable = true;

    settings = {
      preset = "rainbow";
      mode = "rgb";
      light_dark = "dark";
      lightness = 0.5;
      color_align = {
        mode = "horizontal";
        custom_colors = [ ];
        fore_back = null;
      };
    };
  };

  nmt.script = ''
    assertFileContent "home-files/${expectedConfigFile}" ${./hyfetch.json}
    assertPathNotExists "home-files/${unexpectedConfigFile}"
  '';
}
