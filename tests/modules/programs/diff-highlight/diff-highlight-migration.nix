{
  lib,
  options,
  ...
}:

{
  programs.git = {
    enable = true;
    diff-highlight = {
      enable = true;
      pagerOpts = [
        "--tabs=4"
        "-RFX"
      ];
    };
  };

  test.asserts.warnings.expected = [
    "The option `programs.git.diff-highlight.pagerOpts' defined in ${lib.showFiles options.programs.git.diff-highlight.pagerOpts.files} has been renamed to `programs.diff-highlight.pagerOpts'."
    "The option `programs.git.diff-highlight.enable' defined in ${lib.showFiles options.programs.git.diff-highlight.enable.files} has been renamed to `programs.diff-highlight.enable'."
    "`programs.diff-highlight.enableGitIntegration` automatic enablement is deprecated. Please explicitly set `programs.diff-highlight.enableGitIntegration = true`."
  ];

  nmt.script = ''
    # Git config should contain diff-highlight configuration (backward compatibility)
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[core]'
    assertFileRegex home-files/.config/git/config 'pager = .*/diff-highlight.*less'
    assertFileContains home-files/.config/git/config '[interactive]'
    assertFileRegex home-files/.config/git/config 'diffFilter = .*/diff-highlight'
  '';
}
