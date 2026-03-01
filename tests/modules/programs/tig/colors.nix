{ ... }:

{
  programs.tig = {
    enable = true;
    colors = {
      cursor = "yellow red bold";
      title-blur = "white blue";
      title-focus = "white blue bold";
      diff-header = "yellow default";
      diff-chunk = "magenta default";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/tig/config
    assertFileContent home-files/.config/tig/config \
      ${./colors-expected.conf}
  '';
}
