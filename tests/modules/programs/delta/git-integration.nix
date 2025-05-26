{ ... }:
{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config ${./git-integration-expected.conf}
  '';
}
