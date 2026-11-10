{ config, ... }:
{
  programs.pi-coding-agent = {
    enable = true;
    package = null;
    accounts.work.home = ".pi/work";
    settings.theme = "dark";
    context = "Shared account instructions";
    appendSystem = "Shared system instructions";
    keybindings."ctrl+x" = "exit";
    models.providers.local.baseUrl = "http://localhost:1234";
  };
  assertions = [
    {
      assertion = !(config.home.sessionVariables ? PI_CODING_AGENT_DIR);
      message = "An additional account must not change the global pi home.";
    }
  ];
  nmt.script = ''
    for account in .pi/agent .pi/work; do
      assertFileContent "home-files/$account/settings.json" ${./accounts-settings.json}
      assertFileRegex "home-files/$account/AGENTS.md" "Shared account instructions"
      assertFileRegex "home-files/$account/APPEND_SYSTEM.md" "Shared system instructions"
      assertFileRegex "home-files/$account/keybindings.json" "ctrl.x"
      assertFileRegex "home-files/$account/models.json" "http://localhost:1234"
      assertPathNotExists "home-files/$account/auth.json"
      assertPathNotExists "home-files/$account/sessions"
    done
  '';
}
