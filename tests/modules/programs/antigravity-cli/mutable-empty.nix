{ config, ... }:
{
  programs.antigravity-cli = {
    enable = true;
    package = null;
    permissions = { };
    mutableSettings = true;
  };
  assertions = [
    {
      assertion = !(config.home.activation ? antigravitySettings);
      message = "Empty Antigravity settings must not schedule a merge.";
    }
    {
      assertion = !(config.home.activation ? antigravityImmutableSettings);
      message = "Empty Antigravity settings must not schedule cleanup.";
    }
  ];
  nmt.script = ''
    assertPathNotExists home-files/.gemini/antigravity-cli/settings.json
  '';
}
