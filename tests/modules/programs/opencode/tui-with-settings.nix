{ config, ... }:
{
  imports = [ ./opencode-stubs.nix ];

  programs.opencode = {
    enable = true;
    settings = {
      model = "anthropic/claude-sonnet-4-5";
      default_agent = "build";
    };
    tui = {
      theme = "opencode";
    };
    validateFiles.tui = true;
  };

  assertions = [
    {
      assertion = !(config.home.sessionVariables ? OPENCODE_CONFIG);
      message = "OpenCode must not export a settings selector when mutableSettings is disabled.";
    }
    {
      assertion = !(config.home.sessionVariables ? OPENCODE_TUI_CONFIG);
      message = "OpenCode must not export a TUI selector when mutableSettings is disabled.";
    }
  ];

  nmt.script = ''
    assertFileExists home-files/.config/opencode/opencode.json
    assertFileExists home-files/.config/opencode/tui.json
    assertFileContent home-files/.config/opencode/tui.json \
      ${./tui-with-settings-tui.json}
    assertFileContent home-files/.config/opencode/opencode.json \
      ${./tui-with-settings-config.json}
  '';
}
