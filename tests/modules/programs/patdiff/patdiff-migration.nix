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
    "The option `programs.git.patdiff.enable' defined in ${lib.showFiles options.programs.git.patdiff.enable.files} has been changed to `programs.patdiff.enable' that has a different type. Please read `programs.patdiff.enable' documentation and update your configuration accordingly."
    "`programs.patdiff.enableGitIntegration` automatic enablement is deprecated. Please explicitly set `programs.patdiff.enableGitIntegration = true`."
  ];

  nmt.script = ''
    # Git config should contain patdiff configuration (backward compatibility)
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[diff]'
    assertFileRegex home-files/.config/git/config 'external = .*/patdiff-git-wrapper'
  '';
}
