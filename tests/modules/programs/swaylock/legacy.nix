{
  home.stateVersion = "20.09";
  programs.swaylock = {
    settings = {
      color = "808080";
      font-size = 24;
      indicator-idle-visible = false; # Test that this does nothing
      indicator-radius = 100;
      line-color = "ffffff";
      show-failed-attempts = true;
    };
  };

  nmt.script = let homeConfig = "home-files/.config/swaylock/config";
  in ''
    assertFileExists ${homeConfig}
    assertFileContent ${homeConfig} ${./config}
  '';
}
