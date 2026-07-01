{ config, pkgs, ... }:
{
  home.enableNixpkgsReleaseCheck = false;

  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
      version = "3.0.8";
    };

    keyboardShortcuts = {
      "edit-copy" = {
        modifiers = [ "primary" ];
        key = "c";
      };
      "edit-undo" = {
        modifiers = [
          "primary"
          "shift"
        ];
        key = "z";
      };
      "gimp-quit" = {
        key = "q";
      };
      "file-new" = { };
    };
  };

  nmt.script =
    let
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "home-files/Library/Application Support/GIMP/3.0"
        else
          "home-files/.config/GIMP/3.0";
    in
    ''
      assertFileExists "${configDir}/shortcutsrc"
      assertFileRegex "${configDir}/shortcutsrc" '(file-version 1)'
      assertFileRegex "${configDir}/shortcutsrc" '"edit-copy" "<Primary>c"'
      assertFileRegex "${configDir}/shortcutsrc" '"edit-undo" "<Primary><Shift>z"'
      assertFileRegex "${configDir}/shortcutsrc" '"gimp-quit" "q"'
      assertFileRegex "${configDir}/shortcutsrc" '(action "file-new")'
    '';
}
