{ config, ... }:
{
  time = "2026-04-02T00:30:59+00:00";
  condition = config.programs.codex.enable;
  message = ''
    The `programs.codex.rules` option was added to manage Codex `.rules`
    files declaratively.

    Each rule is written under `CODEX_HOME/rules/`, with attribute names
    mapped to `.rules` filenames automatically. Codex uses these rules for
    persistent command-prefix decisions such as allowing recurring safe
    escalations without prompting every time.
  '';
}
