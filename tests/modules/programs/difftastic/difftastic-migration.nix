{
  lib,
  options,
  ...
}:

{
  programs.git = {
    enable = true;
    difftastic = {
      enable = true;
      enableAsDifftool = true;
      options = {
        color = "always";
        display = "side-by-side";
      };
    };
  };

  test.asserts.warnings.expected = [
    "The option `programs.git.difftastic.options' defined in ${lib.showFiles options.programs.git.difftastic.options.files} has been renamed to `programs.difftastic.options'."
    "The option `programs.git.difftastic.enableAsDifftool' defined in ${lib.showFiles options.programs.git.difftastic.enableAsDifftool.files} has been changed to `programs.difftastic.git.mode' that has a different type. Please read `programs.difftastic.git.mode' documentation and update your configuration accordingly."
    "The option `programs.git.difftastic.enable' defined in ${lib.showFiles options.programs.git.difftastic.enable.files} has been renamed to `programs.difftastic.enable'."
    "`programs.difftastic.git.enable` automatic enablement is deprecated. Please explicitly set `programs.difftastic.git.enable = true`."
  ];

  nmt.script = ''
    # Git config should contain difftastic configuration (backward compatibility)
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[diff]'
    assertFileContains home-files/.config/git/config "external = \"@difftastic@/bin/difft '--color=always' '--display=side-by-side'\""
    # Legacy enableAsDifftool = true maps to mode = "both", so difftool is also configured
    assertFileContains home-files/.config/git/config 'tool = "difftastic"'
    assertFileContains home-files/.config/git/config '[difftool "difftastic"]'
    assertFileContains home-files/.config/git/config "cmd = \"@difftastic@/bin/difft '--color=always' '--display=side-by-side' \$LOCAL \$REMOTE\""
  '';
}
