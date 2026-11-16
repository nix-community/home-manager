{
  config,
  pkgs,
  lib,
  ...
}:
let
  launcher =
    if pkgs.stdenv.hostPlatform.isDarwin then
      builtins.head config.launchd.agents.opencode-web.config.ProgramArguments
    else
      builtins.head config.systemd.user.services.opencode-web.Service.ExecStart;
in
{
  imports = [ ./opencode-stubs.nix ];

  test.stubs.opencode.name = "opencode";

  home.file."${config.xdg.configHome}/opencode/home-manager.json" = {
    enable = lib.mkForce true;
    target = lib.mkForce "${config.home.homeDirectory}/layers/config.json";
  };
  home.file."${config.xdg.configHome}/opencode/home-manager-tui.json" = {
    enable = lib.mkForce true;
    target = lib.mkForce ".config/layers/tui.json";
  };
  programs.opencode = {
    enable = true;
    mutableSettings = true;
    settings.model = "example/model";
    tui.theme = "system";
    validateFiles = {
      config = true;
      tui = true;
    };
    web.enable = true;
  };
  assertions = [
    {
      assertion = (
        config.home.sessionVariables.OPENCODE_CONFIG or null == "/home/hm-user/layers/config.json"
      );
      message = "OpenCode services must honor the settings layer enable flag.";
    }
    {
      assertion = (
        config.home.sessionVariables.OPENCODE_TUI_CONFIG or null == "/home/hm-user/.config/layers/tui.json"
      );
      message = "OpenCode services must honor the TUI layer enable flag.";
    }
  ];
  nmt.script = ''
    assertFileContent home-files/layers/config.json ${./layer-service-settings.json}
    assertFileContent home-files/.config/layers/tui.json ${./read-only-layer-tui.json}
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh 'export OPENCODE_CONFIG="/home/hm-user/layers/config.json"'
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh 'export OPENCODE_TUI_CONFIG="/home/hm-user/.config/layers/tui.json"'
    substitute ${./layer-service.sh} "$TMPDIR/launcher-expected.sh" \
      --replace-fail '@shell@' '${pkgs.runtimeShell}' \
      --replace-fail '@opencode@' '${config.programs.opencode.package}'
    assertFileContent "${launcher}" "$TMPDIR/launcher-expected.sh"
  '';
}
