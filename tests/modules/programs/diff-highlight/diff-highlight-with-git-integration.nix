{
  programs.diff-highlight = {
    enable = true;
    enableGitIntegration = true;
    pagerOpts = [
      "--tabs=4"
      "-RFX"
    ];
  };

  programs.git.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[core]'
    assertFileRegex home-files/.config/git/config 'pager = .*/diff-highlight.*less'
    assertFileContains home-files/.config/git/config '[interactive]'
    assertFileRegex home-files/.config/git/config 'diffFilter = .*/diff-highlight'
  '';
}
