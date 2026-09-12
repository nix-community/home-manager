{ lib, ... }:

{
  services.gromit-mpx = {
    enable = true;
    iniSettings = lib.mkDefault {
      Drawing.Opacity = 0.5;
      General.ShowIntroOnStartup = true;
      Custom.Enabled = true;
    };
    tools = [
      {
        device = "default";
        type = "pen";
        size = 5;
      }
      {
        device = "default";
        type = "eraser";
        size = 75;
        modifiers = [ "3" ];
      }
    ];
  };

  nmt.script = (import ./nmt-script.nix ./basic-configuration.cfg) + ''
    assertFileContent home-files/.config/gromit-mpx.ini ${builtins.toFile "expected.ini" ''
      [Custom]
      Enabled=true

      [Drawing]
      Opacity=0.500000

      [General]
      ShowIntroOnStartup=true
    ''}
  '';
}
