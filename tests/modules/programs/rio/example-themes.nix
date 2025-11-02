{ config, ... }:
{
  programs.rio = {
    enable = true;

    package = config.lib.test.mkStubPackage { };

    themes = {
      foobar.colors = {
        cyan = "#8be9fd";
        green = "#50fa7b";
        background = "#282a36";
      };

      foobar2 = ./foobar.toml;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/rio/themes/foobar.toml
    assertFileExists home-files/.config/rio/themes/foobar2.toml

    assertFileContent \
      home-files/.config/rio/themes/foobar.toml \
      ${./foobar.toml}
    assertFileContent \
      home-files/.config/rio/themes/foobar2.toml \
      ${./foobar.toml}
  '';
}
