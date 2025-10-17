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
      options = {
        color = "always";
        display = "side-by-side";
      };
    };
  };

  test.asserts.warnings.expected = [
    "The option `programs.git.difftastic.options' defined in ${lib.showFiles options.programs.git.difftastic.options.files} has been renamed to `programs.difftastic.options'."
    "The option `programs.git.difftastic.enable' defined in ${lib.showFiles options.programs.git.difftastic.enable.files} has been renamed to `programs.difftastic.enable'."
    "`programs.difftastic.git.enable` automatic enablement is deprecated. Please explicitly set `programs.difftastic.git.enable = true`."
  ];

  nmt.script = ''
    # Git config should contain difftastic configuration (backward compatibility)
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[diff]'
    assertFileRegex home-files/.config/git/config 'external = .*/difft.*--color.*--display'
  '';
}
