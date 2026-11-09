{ config, ... }:
{
  programs.claude-code.enable = true;

  programs.peon-ping = {
    enable = true;
    enableClaudeCodeIntegration = true;
    packs = [ ];
  };

  test.stubs.peon-ping = {
    extraAttrs.src = config.lib.test.mkStubPackage {
      name = "peon-ping-src";
      buildScript = ''
        mkdir -p $out/skills/peon-ping-config
        mkdir -p $out/skills/peon-ping-toggle
        mkdir -p $out/skills/peon-ping-use
        echo "# Config skill" > $out/skills/peon-ping-config/SKILL.md
        echo "# Toggle skill" > $out/skills/peon-ping-toggle/SKILL.md
        echo "# Use skill" > $out/skills/peon-ping-use/SKILL.md
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/settings.json
    assertFileContent home-files/.claude/settings.json \
      ${./expected-settings.json}

    assertFileExists home-files/.claude/skills/peon-ping-config/SKILL.md
    assertFileExists home-files/.claude/skills/peon-ping-toggle/SKILL.md
    assertFileExists home-files/.claude/skills/peon-ping-use/SKILL.md
  '';
}
