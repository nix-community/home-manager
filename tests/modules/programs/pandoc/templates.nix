{ config, ... }:

{
  programs.pandoc = {
    enable = true;

    templates = { "default.latex" = ./template.latex; };
  };

  test.stubs.pandoc = import ./stub.nix;

  nmt.script = ''
    assertFileExists  home-files/.local/share/pandoc/templates/default.latex
    assertFileContent home-files/.local/share/pandoc/templates/default.latex \
      ${./template.latex}
  '';
}

