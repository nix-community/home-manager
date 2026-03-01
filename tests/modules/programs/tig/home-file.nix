{ ... }:

{
  programs.tig = {
    enable = true;
    useXdgConfig = false;
    settings = {
      show-rev-graph = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.tigrc
    assertFileContent home-files/.tigrc \
      ${./home-file-expected.conf}
  '';
}
