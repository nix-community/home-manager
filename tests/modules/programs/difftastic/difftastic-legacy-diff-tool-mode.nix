{
  lib,
  options,
  ...
}:

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

  test.asserts.warnings.expected = [
    "The option `programs.difftastic.git.diffToolMode' defined in ${lib.showFiles options.programs.difftastic.git.diffToolMode.files} has been changed to `programs.difftastic.git.mode' that has a different type. Please read `programs.difftastic.git.mode' documentation and update your configuration accordingly."
  ];

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[diff]'
    # Legacy diffToolMode = true should map to mode = "both"
    assertFileContains home-files/.config/git/config "external = \"@difftastic@/bin/difft '--color=always' '--display=side-by-side'\""
    assertFileContains home-files/.config/git/config 'tool = "difftastic"'
    assertFileContains home-files/.config/git/config '[difftool "difftastic"]'
    assertFileContains home-files/.config/git/config "cmd = \"@difftastic@/bin/difft '--color=always' '--display=side-by-side' \$LOCAL \$REMOTE\""
  '';
}
