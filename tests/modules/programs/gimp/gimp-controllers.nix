{ config, pkgs, ... }:
# Covers the full controllerrcc rendering and shortcutsrc renderring
{
  home.enableNixpkgsReleaseCheck = false;

  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
      version = "3.0.8";
    };

    controllers = {
      GimpControllerKeyboard = {
        enabled = true;
        events = [
          {
            stroke = "key-cursor-up";
            action = "tools/gimp-paintbrush";
          }
        ];
      };
      GimpControllerMouse = {
        enabled = false;
        events = [ ];
      };
    };

    extraControllerrc = "(gimp-controllers-extra (GimpInputDeviceCoords (enabled yes) (events ())))\n";

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
      d =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "home-files/Library/Application Support/GIMP/3.0"
        else
          "home-files/.config/GIMP/3.0";
    in
    ''
      assertFileRegex "${d}/controllerrc" "enabled yes"
      assertFileRegex "${d}/controllerrc" "key-cursor-up"
      assertFileRegex "${d}/controllerrc" "enabled no"
      assertFileRegex "${d}/controllerrc" 'mapping'
      assertFileRegex "${d}/controllerrc" 'gimp-controllers-extra'


      assertFileRegex "${d}/shortcutsrc" '"edit-copy" "<Primary>c"'
      assertFileRegex "${d}/shortcutsrc" '"edit-undo" "<Primary><Shift>z"'
      assertFileRegex "${d}/shortcutsrc" '"gimp-quit" "q"'
      assertFileRegex "${d}/shortcutsrc" '(action "file-new")'
    '';
}
