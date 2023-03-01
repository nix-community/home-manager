{ config, ... }:

{
  programs.fuzzel = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      main = {
        font = "Fira Code:size=11";
        dpi-aware = "yes";
      };

      border = { width = 6; };
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/fuzzel/fuzzel.ini \
      ${./example-settings-expected.ini}
  '';
}
