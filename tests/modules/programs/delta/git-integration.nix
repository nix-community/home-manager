{ ... }:
{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config ${substituteExpected ./git-integration-expected.conf}
  '';
}
