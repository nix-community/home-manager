{
  programs.claude-code = {
    enable = true;
    skills = {
      data-processing = ./skill-subdir;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/skills/data-processing/extract.md
    assertFileExists home-files/.claude/skills/data-processing/convert.md
    assertLinkExists home-files/.claude/skills/data-processing/extract.md
    assertLinkExists home-files/.claude/skills/data-processing/convert.md
    assertFileContent \
      home-files/.claude/skills/data-processing/extract.md \
      ${./skill-subdir/extract.md}
    assertFileContent \
      home-files/.claude/skills/data-processing/convert.md \
      ${./skill-subdir/convert.md}
  '';
}
