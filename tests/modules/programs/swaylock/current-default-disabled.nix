{
  home.stateVersion = "23.05";

  programs.swaylock.settings = {
    color = "808080";
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/swaylock/config
  '';
}
