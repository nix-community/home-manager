_:

{
  programs.opencode = {
    enable = true;
    settings.autoupdate = "invalid";
    tui.theme = 0;
    themes = {
      dark = { };
      light = { };
    };
    validation.enable = false;
  };

  home.activation.validateOpenCodeConfigs = "exit 1";

  test.asserts.assertions.expected = [
    "`home.activation.validateOpenCodeConfigs` must not be set when `programs.opencode.validation.enable` is set to `false`"
  ];
}
