{
  programs.difftastic = {
    enable = true;
    git = {
      enable = true;
      diffToolMode = false;
    };
    options = {
      color = "always";
      display = "side-by-side";
      override = [
        "*.mill:Scala"
        "*.yuck:Emacs Lisp"
      ];
    };
  };

  programs.git.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[diff]'
    # Should have diff.external set
    assertFileContains home-files/.config/git/config "external = \"@difftastic@/bin/difft '--color=always' '--display=side-by-side' '--override=*.mill:Scala' '--override=*.yuck:Emacs Lisp'\""
    # Should NOT have difftool config when diffToolMode is explicitly false
    assertFileNotRegex home-files/.config/git/config 'tool = "difftastic"'
    assertFileNotRegex home-files/.config/git/config '\[difftool "difftastic"\]'
  '';
}
