{ config, ... }:
{
  programs.codex = {
    enable = false;
    package = null;
    accounts.work.home = ".codex-work";
    mutableSettings = true;
    settings.model = "shared";
  };
  assertions = [
    {
      assertion = !(config.home.activation ? "codexMutableSettings-work");
      message = "Disabled Codex accounts must not schedule settings activation.";
    }
  ];
  nmt.script = ''
    assertPathNotExists home-files/.codex
    assertPathNotExists home-files/.codex-work
  '';
}
