{ config, ... }:
{
  time = "2026-05-01T16:15:00+00:00";
  condition = config.programs.github-copilot-cli.enable;
  message = ''
    The `programs.github-copilot-cli.context`, `programs.github-copilot-cli.agents`,
    and `programs.github-copilot-cli.skills` options have been added.

    `context` manages `copilot-instructions.md` under `COPILOT_HOME`, while
    `agents` and `skills` let you define custom Copilot CLI agents and skills
    from inline definitions or managed directories.
  '';
}
