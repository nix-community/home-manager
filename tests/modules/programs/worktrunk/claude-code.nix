{ config, ... }:

let
  claudeCodeStub = config.lib.test.mkStubPackage {
    name = "claude-code";
    version = "2.1.157";
    buildScript = ''
      mkdir -p $out/bin
      touch $out/bin/claude
      chmod 755 $out/bin/claude
    '';
  };

  # Stub carrying the installAgentSkills layout (nixpkgs#558216), where the
  # bundled skills moved from $out/skills/ to $out/share/skills/worktrunk/.
  # The module detects the layout at build time, so this must be a real,
  # buildable package with actual files.
  worktrunkStub = config.lib.test.mkStubPackage {
    name = "worktrunk";
    extraAttrs = {
      meta.mainProgram = "wt";
    };
    buildScript = ''
      mkdir -p $out/bin $out/share/skills/worktrunk/wt-switch-create
      printf '#!/bin/sh\n' > $out/bin/wt
      chmod 755 $out/bin/wt
      echo '# wt-switch-create' > $out/share/skills/worktrunk/wt-switch-create/SKILL.md
    '';
  };
in
{
  programs.claude-code = {
    enable = true;
    package = claudeCodeStub;
  };

  programs.worktrunk = {
    enable = true;
    package = worktrunkStub;
    claudeCodeIntegration.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.claude/settings.json
    # The integration wires statusLine, the best-effort activity hooks, and the
    # worktree-isolation hooks through the stubbed `wt` binary.
    assertFileRegex home-files/.claude/settings.json '${worktrunkStub}/bin/wt list statusline --format=claude-code'
    assertFileRegex home-files/.claude/settings.json '"command": "${worktrunkStub}/bin/wt config plugins claude hook || true"'
    assertFileRegex home-files/.claude/settings.json '"command": "${worktrunkStub}/bin/wt config plugins claude hook",$'
    # Skills install as symlinked directories under .claude/skills — not as a
    # bogus key in settings.json — and resolve into the package.
    assertFileExists home-files/.claude/skills/wt-switch-create/SKILL.md
    assertFileContent home-files/.claude/skills/wt-switch-create/SKILL.md \
      ${worktrunkStub}/share/skills/worktrunk/wt-switch-create/SKILL.md
    # configurationSkill is off by default, so /worktrunk is not installed.
    assertPathNotExists home-files/.claude/skills/worktrunk
  '';
}
