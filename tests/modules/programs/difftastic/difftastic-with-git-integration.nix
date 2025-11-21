{
  programs.difftastic = {
    enable = true;
    git.enable = true;
    options = {
      color = "always";
      display = "side-by-side";
    };
  };

  programs.git.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[diff]'
    # Should have diff.external set
    assertFileRegex home-files/.config/git/config 'external = .*/difft.*--color.*--display'
    # Should NOT have difftool config since diffToolMode is false
    assertFileNotRegex home-files/.config/git/config 'tool = "difftastic"'
    assertFileNotRegex home-files/.config/git/config '\[difftool "difftastic"\]'
  '';
}
