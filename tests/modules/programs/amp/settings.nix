{
  lib,
  pkgs,
  config,
  ...
}:

{
  programs.amp = {
    enable = true;
    settings = {
      theme = "solarized_dark";
      tab_width = 2;
      soft_tabs = true;
      line_wrapping = true;
      open_mode.exclusions = [
        "**/.git"
        "**/.svn"
      ];
      line_length_guide = [
        80
        100
      ];
    };
  };

  nmt.script =
    let
      configPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/amp"
        else
          "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/amp";
    in
    ''
      assertFileExists "home-files/${configPath}/config.yml"
      assertFileContent "home-files/${configPath}/config.yml" \
        ${./config.yml}
    '';
}
