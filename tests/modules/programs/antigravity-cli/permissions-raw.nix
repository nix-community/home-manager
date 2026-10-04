{
  config,
  lib,
  ...
}:
let
  cleanup = config.home.activation.antigravityImmutableSettings or null;
  activation = config.home.activation.antigravitySettings or null;
in
{
  programs.antigravity-cli = {
    enable = true;
    package = null;
    mutableSettings = true;
    permissions.deny = [ "command(curl)" ];
    settings.permissions = {
      allow = [ ];
      deny = [ "command(raw)" ];
    };
  };
  assertions = [
    {
      assertion = lib.hasInfix "display_path=${lib.escapeShellArg "/home/hm-user/.gemini/antigravity-cli/settings.json"}\n" config.home.activation.antigravitySettings.data;
      message = "Antigravity settings must merge into the configured destination.";
    }
    {
      assertion = cleanup == null;
      message = "Mutable Antigravity permissions must not schedule immutable cleanup.";
    }
    {
      assertion = activation != null && activation.after == [ "linkGeneration" ];
      message = "Antigravity permissions must merge after linkGeneration.";
    }
  ];

  nmt.script = ''
    assertPathNotExists home-files/.gemini/antigravity-cli/settings.json
    settings="$(grep -m1 -o '/nix/store/[^ ]*-antigravity-cli-settings.json' "$TESTED/activate")" \
      || fail "Missing Antigravity permissions input"
    assertFileContent "$settings" ${./permissions-raw-input.json}
  '';
}
