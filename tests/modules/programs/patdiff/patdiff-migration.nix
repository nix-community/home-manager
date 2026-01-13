{
  lib,
  options,
  ...
}:

{
  programs.git = {
    enable = true;
    patdiff = {
      enable = true;
    };
  };

  test.asserts.warnings.expected = [
    "The option `programs.git.patdiff.enable' defined in ${lib.showFiles options.programs.git.patdiff.enable.files} has been renamed to `programs.patdiff.enable'."
    "`programs.patdiff.enableGitIntegration` automatic enablement is deprecated. Please explicitly set `programs.patdiff.enableGitIntegration = true`."
  ];

  nmt.script = ''
    # Git config should contain patdiff configuration (backward compatibility)
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[diff]'
    assertFileRegex home-files/.config/git/config 'external = .*/patdiff-git-wrapper'
  '';
}
