{ realPkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = realPkgs.ghostty;

    settings = {
      theme = "catppuccin-mocha";
      font-size = 10;
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/ghostty/config \
      ${./example-config-expected}
  '';
}
