{ ... }:

{
  programs.tig = {
    enable = true;
    settings = {
      show-author = "abbreviated";
      show-date = "relative";
      show-rev-graph = true;
      mouse = true;
      tab-size = 4;
      ignore-case = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/tig/config
    assertFileContent home-files/.config/tig/config \
      ${./settings-expected.conf}
  '';
}
