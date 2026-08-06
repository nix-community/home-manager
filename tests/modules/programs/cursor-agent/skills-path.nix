{
  programs.cursor-agent = {
    enable = true;
    package = null;

    skills = {
      deploy-app = ./skills/deploy-app/SKILL.md;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.cursor/skills/deploy-app/SKILL.md
    assertFileContent home-files/.cursor/skills/deploy-app/SKILL.md \
      ${./skills/deploy-app/SKILL.md}
  '';
}
