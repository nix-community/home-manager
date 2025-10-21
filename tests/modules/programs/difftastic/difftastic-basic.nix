{
  programs.difftastic = {
    enable = true;
    options = {
      color = "always";
      display = "side-by-side";
    };
  };
  programs.git.enable = true;

  nmt.script = ''
    # Git config should NOT contain difftastic configuration since git.enable is false by default
    assertFileExists home-files/.config/git/config
    assertFileNotRegex home-files/.config/git/config 'external = .*/difft'
    assertFileNotRegex home-files/.config/git/config 'tool = "difftastic"'
    assertFileNotRegex home-files/.config/git/config '\[difftool "difftastic"\]'
  '';
}
