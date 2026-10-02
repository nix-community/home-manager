{ config, ... }:
{
  programs.trippy.enable = true;
  programs.zsh.enable = true;

  xdg.configFile."trippy/trippy.toml" = {
    text = "[theme-colors]\nbg-color = 'black'\n";
    enable = config.programs.trippy.forceUserConfig;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/trippy/trippy.toml
    assertFileNotRegex home-files/.zshrc 'alias -- trip='
  '';
}
