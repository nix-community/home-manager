{
  programs.silicon = {
    enable = true;
    settings = ''
      --shadow-color '#555'
      --background '#fff'
      --shadow-blur-radius 30
      --no-window-controls
    '';
  };

  test.stubs.silicon = { };

  nmt.script = let configFile = "home-files/.config/silicon/config";
  in ''
    assertFileExists "${configFile}"
    assertFileContent "${configFile}" ${./basic-configuration}
  '';
}
