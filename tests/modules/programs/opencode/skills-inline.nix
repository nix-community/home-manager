{
  programs.opencode = {
    enable = true;
    skills = {
      git-release = ''
        ---
        name: git-release
        description: Create consistent releases and changelogs
        ---

        ## What I do

        - Draft release notes from merged PRs
        - Propose a version bump
        - Provide a copy-pasteable `gh release create` command
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/skill/git-release/SKILL.md
    assertFileContent home-files/.config/opencode/skill/git-release/SKILL.md \
      ${./git-release-SKILL.md}
  '';
}
