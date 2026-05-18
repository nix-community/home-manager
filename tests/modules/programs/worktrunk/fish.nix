{
  programs = {
    worktrunk.enable = true;
    worktrunk.enableFishIntegration = true;
    fish.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileContains \
      home-files/.config/fish/config.fish \
      'eval "$(@worktrunk@ config shell init fish)"'
  '';
}
