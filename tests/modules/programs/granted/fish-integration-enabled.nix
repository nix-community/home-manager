{
  programs = {
    granted.enable = true;
    fish.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/fish/functions/assume.fish
  '';
}
