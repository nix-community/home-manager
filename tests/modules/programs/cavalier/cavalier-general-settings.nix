{ config, pkgs, ... }:

{
  programs.cavalier = {
    enable = true;

    package = config.lib.test.mkStubPackage { };

    settings.general = {
      WindowWidth = 1908;
      WindowHeight = 521;
      WindowMaximized = false;
      AreaMargin = 0;
      AreaOffsetX = 0;
      AreaOffsetY = 0;
      Borderless = false;
      SharpCorners = false;
      ShowControls = false;
      AutohideHeader = false;
      Framerate = 60;
      BarPairs = 6;
      Autosens = true;
      Sensitivity = 10;
      Stereo = true;
      Monstercat = true;
      NoiseReduction = 0.77;
      ReverseOrder = true;
      Direction = 1;
      ItemsOffset = 0.1;
      ItemsRoundness = 0.5;
      Filling = true;
      LinesThickness = 5;
      Mode = 0;
      Mirror = 0;
      ReverseMirror = false;
      InnerRadius = 0.5;
      Rotation = 0;
      ColorProfiles = [{
        Name = "Default";
        FgColors = [ "#ff3584e4" ];
        BgColors = [ "#ff242424" ];
        Theme = 1;
      }];
      ActiveProfile = 0;
      BgImageIndex = -1;
      BgImageScale = 1;
      BgImageAlpha = 1;
      FgImageIndex = -1;
      FgImageScale = 1;
      FgImageAlpha = 1;
    };
  };

  nmt.script = ''
    configFile="home-files/.config/Nickvision Cavalier/config.json"
    assertFileExists "$configFile"
    assertFileContent "$configFile" ${./cavalier-general-settings-expected.json}
  '';
}
