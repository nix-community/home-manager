{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      features = "line-numbers decorations";
      syntax-theme = "Dracula";
      decorations = {
        commit-decoration-style = "bold yellow box ul";
        file-style = "bold yellow ul";
        file-decoration-style = "none";
      };
    };
  };

  programs.git.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[core]'
    assertFileRegex home-files/.config/git/config 'pager = .*/bin/delta'
    assertFileContains home-files/.config/git/config '[interactive]'
    assertFileRegex home-files/.config/git/config 'diffFilter = .*/bin/delta --color-only'
    assertFileContains home-files/.config/git/config '[delta]'
    assertFileContains home-files/.config/git/config 'features = "line-numbers decorations"'
    assertFileContains home-files/.config/git/config 'syntax-theme = "Dracula"'
    assertFileContains home-files/.config/git/config '[delta "decorations"]'
    assertFileContains home-files/.config/git/config 'commit-decoration-style = "bold yellow box ul"'
    assertFileContains home-files/.config/git/config 'file-decoration-style = "none"'
    assertFileContains home-files/.config/git/config 'file-style = "bold yellow ul"'

    # the wrapper should be created only if git integration is disabled
    assertPathNotExists home-path/bin/.delta-wrapped
  '';
}
