{
  programs.satty = {
    enable = true;
    settings = {
      general = {
        fullscreen = true;
        corner-roundness = 12;
        initial-tool = "brush";
        output-filename = "/tmp/test.png";
      };

      font.family = "Roboto";

      color-palette.palette = [ "#00ffff" ];
    };
  };

  nmt.script =
    let
      configFile = "home-files/.config/satty/config.toml";
    in
    ''
      assertFileExists "${configFile}"
      assertFileContent "${configFile}" ${./expected-config.toml}
    '';
}
