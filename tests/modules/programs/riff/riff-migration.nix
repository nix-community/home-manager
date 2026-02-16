{
  lib,
  options,
  ...
}:

{
  programs.git = {
    enable = true;
    riff = {
      enable = true;
      commandLineOptions = [ "--no-adds-only-special" ];
    };
  };

  test.asserts.warnings.expected = [
    "The option `programs.git.riff.commandLineOptions' defined in ${lib.showFiles options.programs.git.riff.commandLineOptions.files} has been renamed to `programs.riff.commandLineOptions'."
    "The option `programs.git.riff.enable' defined in ${lib.showFiles options.programs.git.riff.enable.files} has been renamed to `programs.riff.enable'."
    "`programs.riff.enableGitIntegration` automatic enablement is deprecated. Please explicitly set `programs.riff.enableGitIntegration = true`."
  ];

  nmt.script = ''
    # Git config should contain riff configuration (backward compatibility)
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[pager]'
    assertFileContains home-files/.config/git/config 'diff = "riff"'
    assertFileContains home-files/.config/git/config 'log = "riff"'
    assertFileContains home-files/.config/git/config 'show = "riff"'
    assertFileContains home-files/.config/git/config '[interactive]'
    assertFileContains home-files/.config/git/config 'diffFilter = "riff --color=on"'
  '';
}
