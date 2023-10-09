{ ... }:

{
  programs.broot = {
    enable = true;
    settings.modal = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/broot/conf.toml
    assertFileContains home-files/.config/broot/conf.toml 'modal = true'
  '';
}
