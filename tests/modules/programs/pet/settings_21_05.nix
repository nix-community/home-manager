{
  home.stateVersion = "21.05";
  programs.pet = {
    enable = true;
    settings.editor = "nvim";
  };

  nmt.script = ''
    assertFileContent home-files/.config/pet/config.toml \
      ${./settings_21_05.toml}
  '';
}
