{
  programs.git.enable = true;
  programs.ec.enable = true;
  programs.ec.enableGitIntegration = true;

  nmt.script = ''
    assertFileContent "home-files/.config/git/config" ${./ec-git.conf}
  '';
}
