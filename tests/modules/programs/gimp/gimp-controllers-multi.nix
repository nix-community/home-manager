{ config, ... }:
# Multiple controllers, multiple events — verifies all names and strokes appear.
{
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
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/GIMP/3.0/controllerrc"
    assertFileRegex "home-files/.config/GIMP/3.0/controllerrc" "GimpControllerKeyboard"
    assertFileRegex "home-files/.config/GIMP/3.0/controllerrc" "GimpControllerMouse"
    assertFileRegex "home-files/.config/GIMP/3.0/controllerrc" "key-cursor-up"
    assertFileRegex "home-files/.config/GIMP/3.0/controllerrc" "key-cursor-down"
    assertFileRegex "home-files/.config/GIMP/3.0/controllerrc" "enabled no"
  '';
}
