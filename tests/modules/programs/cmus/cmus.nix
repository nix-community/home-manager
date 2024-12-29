{ ... }:

{
  programs.cmus = {
    enable = true;
    theme = "gruvbox";
    extraConfig = "test";
  };

  test.stubs.cmus = { };

  nmt.script = ''
    assertFileContent \
      home-files/.config/cmus/rc \
      ${
        builtins.toFile "cmus-expected-rc" ''
          colorscheme gruvbox
          test
        ''
      }
  '';
}
