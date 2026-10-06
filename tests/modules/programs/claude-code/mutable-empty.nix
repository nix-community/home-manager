{ config, ... }:
{
  programs.claude-code = {
    enable = true;
    package = null;
    mutableSettings = true;
  };

  assertions = [
    {
      assertion = config.programs.claude-code.mutableSettings;
      message = "Mutable Claude Code settings must remain enabled for an empty configuration.";
    }
    {
      assertion = !(config.home.activation ? claudeCodeSettings);
      message = "Empty Claude Code settings must not register mutable settings activation.";
    }
  ];

  nmt.script = ''
    assertPathNotExists "home-files/.claude/settings.json"
    assertPathNotExists "home-files/.claude/plugins/known_marketplaces.json"
  '';
}
