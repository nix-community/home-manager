{
  programs.diff-so-fancy = {
    enable = true;
    settings = {
      markEmptyLines = false;
      changeHunkIndicators = true;
    };
  };
  programs.git.enable = true;

  nmt.script = ''
    # Git config should NOT contain diff-so-fancy configuration since enableGitIntegration is false by default
    assertFileNotRegex home-files/.config/git/config 'pager = .*/diff-so-fancy'
    assertFileNotRegex home-files/.config/git/config 'diffFilter = .*/diff-so-fancy'
  '';
}
