{
  programs.opencode = {
    enable = true;
    skills = {
      data-analysis = ./skill-dir/data-analysis;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/skill/data-analysis/SKILL.md
    assertFileExists home-files/.config/opencode/skill/data-analysis/notes.txt
    assertFileContent home-files/.config/opencode/skill/data-analysis/SKILL.md \
      ${./skill-dir/data-analysis/SKILL.md}
  '';
}
