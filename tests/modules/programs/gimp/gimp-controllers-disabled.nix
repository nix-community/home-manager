{ config, ... }:
# enabled = false should render as "(enabled no)".
{
  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
      version = "3.0.8";
    };

    controllers = {
      GimpControllerMouse = {
        enabled = false;
        events = [ ];
      };
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/GIMP/3.0/controllerrc"
    assertFileRegex "home-files/.config/GIMP/3.0/controllerrc" "GimpControllerMouse"
    assertFileRegex "home-files/.config/GIMP/3.0/controllerrc" "enabled no"
  '';
}
