{ config, ... }:
{
  programs.claude-code = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "claude-code";
      version = "2.1.157";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/claude
        chmod 755 $out/bin/claude
      '';
    };
  };

  # The integration is opt-in: enabling programs.worktrunk alone must not
  # touch programs.claude-code. configurationSkill stays at its default (off),
  # so only /wt-switch-create should be installed — not the /worktrunk config
  # skill.
  programs.worktrunk = {
    enable = true;
    claudeCodeIntegration.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.claude/settings.json
    # The integration wires statusLine, the activity state-marker hook, and the
    # worktree-isolation hook through `wt` (scrubbed to @worktrunk@ in tests).
    # We match stable substrings because WorktreeCreate/Remove also embed the jq
    # store path, which the test harness does not scrub.
    assertFileRegex home-files/.claude/settings.json '@worktrunk@/bin/wt list statusline --format=claude-code'
    assertFileRegex home-files/.claude/settings.json '@worktrunk@/bin/wt config state marker set 🤖'
    assertFileRegex home-files/.claude/settings.json '@worktrunk@/bin/wt switch --create'
    # Skills install as directories under .claude/skills — not as a bogus key in
    # settings.json.
    assertFileExists home-files/.claude/skills/wt-switch-create/SKILL.md
    # configurationSkill is off by default, so /worktrunk is not installed.
    assertPathNotExists home-files/.claude/skills/worktrunk
  '';
}
