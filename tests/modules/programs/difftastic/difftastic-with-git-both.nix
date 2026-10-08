{
  programs.difftastic = {
    enable = true;
    git = {
      enable = true;
      mode = "both";
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
    # Should have BOTH diff.external AND difftool config when mode is "both"
    assertFileContains home-files/.config/git/config "external = \"@difftastic@/bin/difft '--color=always' '--display=side-by-side'\""
    assertFileContains home-files/.config/git/config 'tool = "difftastic"'
    assertFileContains home-files/.config/git/config '[difftool "difftastic"]'
    assertFileContains home-files/.config/git/config "cmd = \"@difftastic@/bin/difft '--color=always' '--display=side-by-side' \$LOCAL \$REMOTE\""
  '';
}
