{
  programs.crush = {
    enable = true;
    package = null;

    skills = {
      git-release = ''
        ---
        name: git-release
        description: Create consistent releases and changelogs
        ---

        ## What I do

        - Draft release notes from merged PRs
        - Propose a version bump
      '';

      pdf-processing = ./pdf-processing-SKILL.md;

      data-analysis = ./skill-dir;
    };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/crush/crush.json

    assertFileContent home-files/.config/crush/skills/git-release/SKILL.md \
      ${./git-release-SKILL.md}

    assertFileContent home-files/.config/crush/skills/pdf-processing/SKILL.md \
      ${./pdf-processing-SKILL.md}

    assertFileContent home-files/.config/crush/skills/data-analysis/SKILL.md \
      ${./skill-dir/SKILL.md}
    assertFileExists home-files/.config/crush/skills/data-analysis/reference.md
  '';
}
