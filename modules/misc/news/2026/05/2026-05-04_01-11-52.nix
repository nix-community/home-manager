{
  time = "2026-05-03T16:11:52+00:00";
  message = ''
    A new module is available: `programs.agent-skills`.

    It defines skill bundles and named skills for AI coding agent
    CLIs, materialized under {file}`~/.agents/skills/` where
    several agents auto-discover them.

    Claude Code reads skills from the {file}`skills/` subdirectory
    of {option}`programs.claude-code.configDir` instead; set
    {option}`programs.claude-code.enableSkillsIntegration` to
    `true` to materialize the shared skills there as well.
  '';
}
