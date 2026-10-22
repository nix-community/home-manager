{
  config,
  lib,
  realPkgs,
  ...
}:
let
  cli = {
    theme.name = "system";
    tabs.mode = "off";
    plugins = [ "plugin-$HOME-\"quoted\"-`cmd`" ];
  };
  expectedCli = builtins.toJSON (
    {
      "$schema" = "https://opencode.ai/v2/cli.json";
    }
    // cli
  );
in
{
  imports = [ ./opencode-v2-stubs.nix ];

  programs.opencode = {
    enable = true;
    mutableSettings = true;
    inherit cli;
    validateFiles.cli = true;
  };

  assertions = [
    {
      assertion = config.home.sessionVariables ? OPENCODE_CLI_CONFIG_CONTENT;
      message = "OpenCode must export the CLI settings layer through OPENCODE_CLI_CONFIG_CONTENT.";
    }
    {
      assertion = !(config.home.sessionVariables ? OPENCODE_CONFIG);
      message = "OpenCode must not export a settings selector for an empty settings layer.";
    }
    {
      assertion = !(config.home.sessionVariables ? OPENCODE_TUI_CONFIG);
      message = "OpenCode must not export a TUI selector for an empty TUI layer.";
    }
  ];

  nmt.script = ''
    assertFileContent home-files/.config/opencode/home-manager-cli.json \
      ${./cli-layer.json}
    assertPathNotExists home-files/.config/opencode/cli.json
    ${lib.getExe realPkgs.bash} -c '
      . "$1"
      test "$OPENCODE_CLI_CONFIG_CONTENT" = "$2"
    ' -- "$TESTED/home-path/etc/profile.d/hm-session-vars.sh" '${expectedCli}' \
      || fail "OpenCode CLI settings must preserve JSON content through the session variable"
  '';
}
