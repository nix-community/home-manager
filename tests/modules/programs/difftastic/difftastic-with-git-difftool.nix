{
  programs.difftastic = {
    enable = true;
    git = {
      enable = true;
      mode = "difftool";
    };
    options = {
      color = "always";
      display = "side-by-side";
    };
  };

  programs.git.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    # Should have difftool config only, leaving `git diff` untouched
    assertFileContains home-files/.config/git/config 'tool = "difftastic"'
    assertFileContains home-files/.config/git/config '[difftool "difftastic"]'
    assertFileContains home-files/.config/git/config "cmd = \"@difftastic@/bin/difft '--color=always' '--display=side-by-side' \$LOCAL \$REMOTE\""
    # Should NOT have diff.external when mode is "difftool"
    assertFileNotRegex home-files/.config/git/config 'external = .*/difft'
  '';
}
