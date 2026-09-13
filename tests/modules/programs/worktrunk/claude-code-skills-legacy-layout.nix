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

  # Real (buildable) stub carrying the pre-installAgentSkills skills layout.
  # The module probes the package at build time to locate its skills
  # directory, so the test must provide actual files. The default test
  # package, scrubbed to the "@worktrunk@" placeholder path, is not enough:
  # the probe would produce a dangling symlink and fail the build.
  worktrunkStub = config.lib.test.mkStubPackage {
    name = "worktrunk";
    extraAttrs = {
      meta.mainProgram = "wt";
    };
    buildScript = ''
      mkdir -p $out/bin $out/skills/wt-switch-create
      printf '#!/bin/sh\n' > $out/bin/wt
      chmod 755 $out/bin/wt
      echo '# wt-switch-create' > $out/skills/wt-switch-create/SKILL.md
    '';
  };
in
{
  programs.claude-code = {
    enable = true;
    package = claudeCodeStub;
  };

  # The integration is opt-in: enabling programs.worktrunk alone must not
  # touch programs.claude-code. configurationSkill stays at its default (off),
  # so only /wt-switch-create should be installed — not the /worktrunk config
  # skill.
  programs.worktrunk = {
    enable = true;
    package = worktrunkStub;
    claudeCodeIntegration.enable = true;
  };

  # The skills must be picked up from the legacy share/ layout and resolve
  # into the package.
  nmt.script = ''
    assertFileExists home-files/.claude/skills/wt-switch-create/SKILL.md
    assertFileContent home-files/.claude/skills/wt-switch-create/SKILL.md \
      ${worktrunkStub}/skills/wt-switch-create/SKILL.md
  '';
}
