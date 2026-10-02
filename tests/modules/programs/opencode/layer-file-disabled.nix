{ config, lib, ... }:
{
  xdg.configFile."opencode/home-manager.json" = {
    target = "${config.home.homeDirectory}/layers/opencode.json";
    enable = false;
  };
  xdg.configFile."opencode/home-manager-tui.json" = {
    target = "layers/tui.json";
    enable = false;
  };
  programs.opencode = {
    enable = true;
    mutableSettings = true;
    package = null;
    settings.permission.bash = {
      "aa *" = lib.hm.dag.entryAfter [ "zz *" ] "allow";
      "zz *" = "ask";
    };
    tui.theme = "system";
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
    assertPathNotExists "home-files/layers/opencode.json"
    assertPathNotExists "home-files/.config/layers/tui.json"
    assertPathNotExists "home-files/.config/opencode/opencode.json"
    assertPathNotExists "home-files/.config/opencode/tui.json"
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
  '';
}
