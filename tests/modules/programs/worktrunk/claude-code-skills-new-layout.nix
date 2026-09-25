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
    # The skills must be picked up from the new share/skills/worktrunk
    # layout and resolve into the package.
    assertFileExists home-files/.claude/skills/wt-switch-create/SKILL.md
    assertFileContent home-files/.claude/skills/wt-switch-create/SKILL.md \
      ${worktrunkStub}/share/skills/worktrunk/wt-switch-create/SKILL.md
  '';
}
