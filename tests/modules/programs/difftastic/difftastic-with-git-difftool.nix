{
  programs.difftastic = {
    enable = true;
    git = {
      enable = true;
      diffToolMode = true;
    };
    options = {
      color = "always";
      display = "side-by-side";
    };
  };

  programs.git.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[diff]'
    # Should have BOTH diff.external AND difftool config when diffToolMode is true
    assertFileRegex home-files/.config/git/config 'external = .*/difft.*--color.*--display'
    assertFileRegex home-files/.config/git/config 'tool = "difftastic"'
    assertFileContains home-files/.config/git/config '[difftool "difftastic"]'
    assertFileRegex home-files/.config/git/config 'cmd = .*/difft.*--color.*--display.*\$LOCAL \$REMOTE'
  '';
}
