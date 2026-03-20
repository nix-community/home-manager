{
  programs.diff-highlight = {
    enable = true;
    pagerOpts = [
      "--tabs=4"
      "-RFX"
    ];
  };
  programs.git.enable = true;

  nmt.script = ''
    # Git config should NOT contain diff-highlight configuration since enableGitIntegration is false by default
    assertFileNotRegex home-files/.config/git/config 'pager = .*/diff-highlight'
    assertFileNotRegex home-files/.config/git/config 'diffFilter = .*/diff-highlight'
  '';
}
