{ ... }:

{
  programs = {
    scmpuff = {
      enable = true;
      enableBashIntegration = false;
    };
    bash.enable = true;
  };

  test.stubs.scmpuff = { };

  nmt.script = ''
    assertFileNotRegex home-files/.bashrc '@scmpuff@/bin/scmpuff'
  '';
}
