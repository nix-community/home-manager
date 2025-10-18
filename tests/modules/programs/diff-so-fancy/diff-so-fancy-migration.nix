{
  lib,
  options,
  ...
}:

{
  programs.git = {
    enable = true;
    diff-so-fancy = {
      enable = true;
      markEmptyLines = false;
      changeHunkIndicators = true;
    };
  };

  test.asserts.warnings.expected = [
    "The option `programs.git.diff-so-fancy.changeHunkIndicators' defined in ${lib.showFiles options.programs.git.diff-so-fancy.changeHunkIndicators.files} has been renamed to `programs.diff-so-fancy.settings.changeHunkIndicators'."
    "The option `programs.git.diff-so-fancy.markEmptyLines' defined in ${lib.showFiles options.programs.git.diff-so-fancy.markEmptyLines.files} has been renamed to `programs.diff-so-fancy.settings.markEmptyLines'."
    "The option `programs.git.diff-so-fancy.enable' defined in ${lib.showFiles options.programs.git.diff-so-fancy.enable.files} has been renamed to `programs.diff-so-fancy.enable'."
    "`programs.diff-so-fancy.enableGitIntegration` automatic enablement is deprecated. Please explicitly set `programs.diff-so-fancy.enableGitIntegration = true`."
  ];

  nmt.script = ''
    # Git config should contain diff-so-fancy configuration (backward compatibility)
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[core]'
    assertFileRegex home-files/.config/git/config 'pager = .*/diff-so-fancy.*less'
    assertFileContains home-files/.config/git/config '[interactive]'
    assertFileRegex home-files/.config/git/config 'diffFilter = .*/diff-so-fancy --patch'
    assertFileContains home-files/.config/git/config '[diff-so-fancy]'
    assertFileContains home-files/.config/git/config 'markEmptyLines = false'
    assertFileContains home-files/.config/git/config 'changeHunkIndicators = true'
  '';
}
