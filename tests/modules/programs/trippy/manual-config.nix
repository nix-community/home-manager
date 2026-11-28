{
  programs.trippy = {
    enable = true;
    forceUserConfig = true;
  };
  programs.zsh.enable = true;

  xdg.configFile."trippy/trippy.toml".text = "[theme-colors]\nbg-color = 'black'\n";

  nmt.script = ''
    assertFileExists home-files/.config/trippy/trippy.toml
    assertFileContains home-files/.config/trippy/trippy.toml "bg-color = 'black'"
    assertFileContains home-files/.zshrc \
      "alias -- trip='trip -c /home/hm-user/.config/trippy/trippy.toml'"
  '';
}
