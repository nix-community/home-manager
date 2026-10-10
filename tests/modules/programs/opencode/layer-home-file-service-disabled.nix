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
  home.file."${config.xdg.configHome}/opencode/home-manager.json" = {
    enable = lib.mkForce false;
    target = lib.mkForce "${config.home.homeDirectory}/layers/config.json";
  };
  home.file."${config.xdg.configHome}/opencode/home-manager-tui.json" = {
    enable = lib.mkForce false;
    target = lib.mkForce ".config/layers/tui.json";
  };
  programs.opencode = {
    enable = true;
    mutableSettings = true;
    settings.model = "example/model";
    tui.theme = "system";
    web.enable = true;
  };
  assertions = [
    {
      assertion = !(config.home.sessionVariables ? OPENCODE_CONFIG);
      message = "OpenCode services must honor the settings layer enable flag.";
    }
    {
      assertion = !(config.home.sessionVariables ? OPENCODE_TUI_CONFIG);
      message = "OpenCode services must honor the TUI layer enable flag.";
    }
  ];
  nmt.script = ''
    assertPathNotExists home-files/layers/config.json
    assertPathNotExists home-files/.config/layers/tui.json
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'OPENCODE_(TUI_)?CONFIG'
    substitute ${./layer-service-disabled.sh} "$TMPDIR/launcher-expected.sh" \
      --replace-fail '@shell@' '${pkgs.runtimeShell}' \
      --replace-fail '@opencode@' '${config.programs.opencode.package}'
    assertFileContent "${launcher}" "$TMPDIR/launcher-expected.sh"
  '';
}
