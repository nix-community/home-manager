{
  programs.pandoc = {
    enable = true;

    citationStyles = [ ./example.csl ];
  };

  test.stubs.pandoc = import ./stub.nix;

  nmt.script = ''
    assertFileExists  home-files/.local/share/pandoc/csl/example.csl
    assertFileContent home-files/.local/share/pandoc/csl/example.csl \
      ${./example.csl}
  '';
}

