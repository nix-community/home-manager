{
  programs = {
    fish.enable = true;

    starship = {
      enable = true;
      enableTransience = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileRegex home-files/.config/fish/config.fish 'enable_transience'
  '';
}
