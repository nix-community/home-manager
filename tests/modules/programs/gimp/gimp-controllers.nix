{ config, pkgs, ... }:
# Covers all controllerrc rendering cases:
#   enabled = true/false   → "enabled yes" / "enabled no"
#   non-empty events list  → stroke+action pairs
#   empty events list      → "()" nil sentinel
#   multiple controllers   → all appear in one file
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
          {
            stroke = "key-cursor-down";
            action = "context/gimp-context-opacity-decrease";
          }
        ];
      };
      GimpControllerMouse = {
        enabled = false;
        events = [ ];
      };
      GimpControllerWheel = {
        enabled = true;
        events = [ ]; # empty → () nil sentinel
      };
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
      assertFileExists "${configDir}/controllerrc"
      assertFileRegex "${configDir}/controllerrc" "GimpControllerKeyboard"
      assertFileRegex "${configDir}/controllerrc" "enabled yes"
      assertFileRegex "${configDir}/controllerrc" "key-cursor-up"
      assertFileRegex "${configDir}/controllerrc" "key-cursor-down"
      assertFileRegex "${configDir}/controllerrc" "gimp-context-opacity-decrease"
      assertFileRegex "${configDir}/controllerrc" "GimpControllerMouse"
      assertFileRegex "${configDir}/controllerrc" "enabled no"
      assertFileRegex "${configDir}/controllerrc" "GimpControllerWheel"
      assertFileRegex "${configDir}/controllerrc" "\(\)"
    '';
}
