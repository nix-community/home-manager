{ config, ... }:
{
  time = "2026-05-01T17:00:00+00:00";
  condition = config.programs.github-copilot-cli.enable;
  message = ''
    The `programs.github-copilot-cli.lspServers` option has been added.

    This option manages the `lsp-config.json` file under `COPILOT_HOME`,
    allowing GitHub Copilot CLI to start configured language servers for code
    intelligence features.
  '';
}
