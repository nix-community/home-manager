{
  lib,
  options,
  ...
}:

{
  programs.git = {
    enable = true;
    delta = {
      enable = true;
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
  };

  test.asserts.warnings.expected = [
    "The option `programs.git.delta.options' defined in ${lib.showFiles options.programs.git.delta.options.files} has been renamed to `programs.delta.options'."
    "The option `programs.git.delta.enable' defined in ${lib.showFiles options.programs.git.delta.enable.files} has been renamed to `programs.delta.enable'."
    "`programs.delta.enableGitIntegration` automatic enablement is deprecated. Please explicitly set `programs.delta.enableGitIntegration = true`."
  ];

  nmt.script = ''
    # Git config should contain delta configuration (backward compatibility)
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
  '';
}
