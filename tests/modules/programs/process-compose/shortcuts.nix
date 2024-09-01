{ config, pkgs, ... }:

{
  config = {
    programs.process-compose = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-process-compose" "";
      shortcuts = { help.shortcut = "?"; };
    };

    nmt.script = let
      configDir = if pkgs.stdenv.isDarwin then
        "home-files/Library/Application Support/process-compose"
      else
        "home-files/.config/process-compose";
    in ''
      shortcutsFile="${configDir}/shortcuts.yaml"
      assertFileExists "$shortcutsFile"
      assertFileContent "$shortcutsFile" "${./shortcuts.yaml}"
    '';
  };
}
