{ ... }:

{
  programs.broot = {
    enable = true;
    settings.modal = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/broot/conf.hjson
    assertFileContains home-files/.config/broot/conf.hjson '"modal": true'
  '';
}
