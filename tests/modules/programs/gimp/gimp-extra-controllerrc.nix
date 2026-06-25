{ config, pkgs, ... }:
# extraControllerrc raw lines are appended after any generated controller blocks.
# Also exercises the standalone case: extraControllerrc alone triggers file creation
# even when controllers = {} (the condition is `controllers != {} || extraControllerrc != ""`).
{
  home.enableNixpkgsReleaseCheck = false;

  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
      version = "3.0.8";
    };

    controllers.GimpControllerKeyboard = {
      enabled = true;
      events = [
        {
          stroke = "key-cursor-up";
          action = "tools/gimp-paintbrush";
        }
      ];
    };

    extraControllerrc = ''
      (gimp-controllers-extra
          (GimpInputDeviceCoords
              (enabled yes)
              (events
                  ())))
    '';
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
      # Generated section comes first
      assertFileRegex "${configDir}/controllerrc" "GimpControllerKeyboard"
      assertFileRegex "${configDir}/controllerrc" "key-cursor-up"
      # extraControllerrc appended after
      assertFileRegex "${configDir}/controllerrc" "GimpInputDeviceCoords"
      assertFileRegex "${configDir}/controllerrc" "gimp-controllers-extra"
    '';
}
