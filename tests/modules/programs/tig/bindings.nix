{ ... }:

{
  programs.tig = {
    enable = true;
    bindings = {
      generic = {
        g = "move-first-line";
        G = "move-last-line";
      };
      main = {
        C = "!git cherry-pick %(commit)";
      };
    };
    colors = {
      cursor = "yellow red bold";
      title-focus = "white blue bold";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/tig/config
    assertFileContent home-files/.config/tig/config \
      ${./bindings-expected.conf}
  '';
}
