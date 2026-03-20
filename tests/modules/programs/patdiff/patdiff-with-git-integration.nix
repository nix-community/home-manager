{
  programs.patdiff = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[diff]'
    assertFileRegex home-files/.config/git/config 'external = .*/patdiff-git-wrapper'
  '';
}
