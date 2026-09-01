{
  services.gromit-mpx = {
    enable = true;
    iniSettings = {
      General.ShowIntroOnStartup = true;
      Drawing.Opacity = "0.5";
    };
    tools = [
      {
        device = "stylus";
        color = "#ff00ff";
        size = 3;
      }
    ];
    cfgSettings = ''
      custom cfg settings
    '';
  };

  nmt.script = ''
    assertFileContent home-files/.config/gromit-mpx.ini ${builtins.toFile "gromit-mpx.ini" ''
      [Drawing]
      Opacity=0.5

      [General]
      ShowIntroOnStartup=true
    ''}
    assertFileContent home-files/.config/gromit-mpx.cfg ${builtins.toFile "gromit-mpx.cfg" ''
      "tool-1" = PEN (size=3 color="#ff00ff");
      "stylus" = "tool-1";

      custom cfg settings
    ''}
  '';
}
