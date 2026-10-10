{
  config,
  lib,
  realPkgs,
  ...
}:
{
  xdg.configFile."opencode/home-manager.json" = {
    target = "${config.home.homeDirectory}/layers/my % $hm_layer_probe \"quoted\" back\\$hm_layer_probe `printf altered` settings.json";
    enable = true;
  };
  xdg.configFile."opencode/home-manager-tui.json" = {
    target = "layers/my % $hm_layer_probe \"quoted\" back\\$hm_layer_probe `printf altered` tui.json";
    enable = true;
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
      assertion = (config.home.sessionVariables ? OPENCODE_CONFIG);
      message = "OpenCode must export a settings selector only for an enabled nonempty layer.";
    }
    {
      assertion = (config.home.sessionVariables ? OPENCODE_TUI_CONFIG);
      message = "OpenCode must export a TUI selector only for an enabled nonempty layer.";
    }
  ];
  nmt.script = ''
    assertFileContent 'home-files/layers/my % $hm_layer_probe "quoted" back\$hm_layer_probe `printf altered` settings.json' ${./settings-ordered-permissions.json}
    assertFileContent 'home-files/.config/layers/my % $hm_layer_probe "quoted" back\$hm_layer_probe `printf altered` tui.json' ${./read-only-layer-tui.json}
    assertPathNotExists "home-files/.config/opencode/opencode.json"
    assertPathNotExists "home-files/.config/opencode/tui.json"
    ${lib.getExe realPkgs.bash} -c '
      . "$1"
      test "$OPENCODE_CONFIG" = "$2" && test "$OPENCODE_TUI_CONFIG" = "$3"
    ' -- "$TESTED/home-path/etc/profile.d/hm-session-vars.sh" \
      '/home/hm-user/layers/my % $hm_layer_probe "quoted" back\$hm_layer_probe `printf altered` settings.json' \
      '/home/hm-user/.config/layers/my % $hm_layer_probe "quoted" back\$hm_layer_probe `printf altered` tui.json' \
      || fail "OpenCode session selectors must preserve literal filenames"
  '';
}
