{ config, ... }:
{
  programs.claude-code = {
    enable = false;
    accounts.work.home = ".disabled-account";
    package = null;
    mutableSettings = true;
    settings.theme = "dark";
  };

  assertions = [
    {
      assertion = config.programs.claude-code.mutableSettings;
      message = "Mutable Claude Code settings must remain enabled while the module is disabled.";
    }
    {
      assertion = !(config.home.activation ? claudeCodeSettings);
      message = "Disabled Claude Code must not register mutable settings activation.";
    }
  ];

  nmt.script = ''
    assertPathNotExists "home-files/.disabled-account"
    assertPathNotExists "home-files/.claude/settings.json"
    assertPathNotExists "home-files/.claude/plugins/known_marketplaces.json"
  '';
}
