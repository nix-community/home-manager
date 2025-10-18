{
  programs.diff-so-fancy = {
    enable = true;
    enableGitIntegration = true;
    settings = {
      markEmptyLines = false;
      changeHunkIndicators = true;
      stripLeadingSymbols = false;
    };
  };

  programs.git.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[core]'
    assertFileRegex home-files/.config/git/config 'pager = .*/diff-so-fancy.*less'
    assertFileContains home-files/.config/git/config '[interactive]'
    assertFileRegex home-files/.config/git/config 'diffFilter = .*/diff-so-fancy --patch'
    assertFileContains home-files/.config/git/config '[diff-so-fancy]'
    assertFileContains home-files/.config/git/config 'markEmptyLines = false'
    assertFileContains home-files/.config/git/config 'changeHunkIndicators = true'
    assertFileContains home-files/.config/git/config 'stripLeadingSymbols = false'
  '';
}
