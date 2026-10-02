{ config, lib, ... }:
{
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
      assertion = (config.home.sessionVariables ? OPENCODE_CONFIG);
      message = "OpenCode must export a settings selector only for an enabled nonempty layer.";
    }
    {
      assertion = (config.home.sessionVariables ? OPENCODE_TUI_CONFIG);
      message = "OpenCode must export a TUI selector only for an enabled nonempty layer.";
    }
  ];
  nmt.script = ''
    assertFileContent "home-files/.config/opencode/home-manager.json" ${./settings-ordered-permissions.json}
    assertFileContent "home-files/.config/opencode/home-manager-tui.json" ${./read-only-layer-tui.json}
    assertPathNotExists "home-files/.config/opencode/opencode.json"
    assertPathNotExists "home-files/.config/opencode/tui.json"
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh 'export OPENCODE_CONFIG="${config.home.homeDirectory}/.config/opencode/home-manager.json"'
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh 'export OPENCODE_TUI_CONFIG="${config.home.homeDirectory}/.config/opencode/home-manager-tui.json"'
  '';
}
