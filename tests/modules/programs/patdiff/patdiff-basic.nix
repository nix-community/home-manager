{
  programs.patdiff = {
    enable = true;
  };
  programs.git.enable = true;

  nmt.script = ''
    # Git config should NOT contain patdiff configuration since enableGitIntegration is false by default
    assertFileNotRegex home-files/.config/git/config 'external = .*/patdiff-git-wrapper'
  '';
}
