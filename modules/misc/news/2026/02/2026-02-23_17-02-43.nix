{ config, ... }:
{
  time = "2026-02-23T17:02:43+00:00";
  condition = config.programs.mergiraf.enable;
  message = ''
    The `programs.mergiraf` module's Git and Jujutsu integration are now gated
    behind `programs.mergiraf.enableGitIntegration` (respectively
    `enableJujutsuIntegration`).

    They are enabled by default for `stateVersion < 26.05`, and otherwise need
    to be explicitly enabled.
  '';
}
