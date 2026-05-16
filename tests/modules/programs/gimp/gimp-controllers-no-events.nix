{ config, ... }:
# An empty events list serialises as () — GIMP's nil sentinel.
{
  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
      version = "3.0.8";
    };

    controllers = {
      GimpControllerWheel = {
        enabled = true;
        events = [ ];
      };
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/GIMP/3.0/controllerrc"
    assertFileRegex "home-files/.config/GIMP/3.0/controllerrc" "GimpControllerWheel"
    assertFileRegex "home-files/.config/GIMP/3.0/controllerrc" "enabled yes"
  '';
}
