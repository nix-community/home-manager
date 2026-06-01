{ config, ... }:
{
  programs.claude-code = {
    enable = true;
    configDir = "${config.xdg.configHome}/claude";

    settings = {
      theme = "dark";
    };

    context = ''
      # Custom context
    '';

    agents = {
      reviewer = ''
        ---
        name: reviewer
        description: code reviewer
        ---
        body
      '';
    };

    commands = {
      hello = ''
        ---
        description: hello command
        ---
        body
      '';
    };

    rules = {
      style = "rule body";
    };

    hooks = {
      pre-edit = ''
        #!/usr/bin/env bash
        echo hi
      '';
    };

    outputStyles = {
      concise = "concise body";
    };

    skills = {
      pdf = ''
        ---
        name: pdf
        description: pdf skill
        ---
        body
      '';
    };
  };

  nmt.script = ''
    assertPathNotExists home-files/.claude

    assertFileExists home-files/.config/claude/settings.json
    assertFileExists home-files/.config/claude/CLAUDE.md
    assertFileExists home-files/.config/claude/agents/reviewer.md
    assertFileExists home-files/.config/claude/commands/hello.md
    assertFileExists home-files/.config/claude/rules/style.md
    assertFileExists home-files/.config/claude/hooks/pre-edit
    assertFileIsExecutable home-files/.config/claude/hooks/pre-edit
    assertFileExists home-files/.config/claude/output-styles/concise.md
    assertFileExists home-files/.config/claude/skills/pdf/SKILL.md

    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'export CLAUDE_CONFIG_DIR="/home/hm-user/.config/claude"'
  '';
}
