{ config, ... }:
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
        ];
      };
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/GIMP/3.0/controllerrc"
    assertFileRegex "home-files/.config/GIMP/3.0/controllerrc" "GimpControllerKeyboard"
    assertFileRegex "home-files/.config/GIMP/3.0/controllerrc" "enabled yes"
    assertFileRegex "home-files/.config/GIMP/3.0/controllerrc" "key-cursor-up"
    assertFileRegex "home-files/.config/GIMP/3.0/controllerrc" "gimp-paintbrush"
  '';
}
