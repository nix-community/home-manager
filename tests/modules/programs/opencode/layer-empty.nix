{ config, ... }:
{
  programs.opencode = {
    enable = true;
    mutableSettings = true;
    package = null;
    settings = { };
    tui = { };
  };
  assertions = [
    {
      assertion = !(config.home.sessionVariables ? OPENCODE_CONFIG);
      message = "OpenCode must export a settings selector only for an enabled nonempty layer.";
    }
    {
      assertion = !(config.home.sessionVariables ? OPENCODE_TUI_CONFIG);
      message = "OpenCode must export a TUI selector only for an enabled nonempty layer.";
    }
  ];
  nmt.script = ''
    assertPathNotExists "home-files/.config/opencode/home-manager.json"
    assertPathNotExists "home-files/.config/opencode/home-manager-tui.json"
    assertPathNotExists "home-files/.config/opencode/opencode.json"
    assertPathNotExists "home-files/.config/opencode/tui.json"
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
  '';
}
