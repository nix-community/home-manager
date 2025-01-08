{ ... }:

{
  programs.broot = {
    enable = true;
    settings.modal = true;
  };

  tests.stubs = {
    broot = { };
    hjson = { };
  };

  nmt.script = ''
    assertFileExists home-files/.config/broot/conf.toml
    assertFileContains home-files/.config/broot/conf.toml 'modal = true'
  '';
}
