{
  programs = {
    granted.enable = true;
    granted.enableFishIntegration = false;
    fish.enable = true;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/fish/functions/assume.fish
  '';
}
