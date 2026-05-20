{ pkgs, ... }:

{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "antigravity-cli" "";
    skills = ./skills;
  };

  nmt.script = ''
    assertFileExists home-files/.gemini/config/skills/xlsx/SKILL.md
    assertLinkExists home-files/.gemini/config/skills/xlsx/SKILL.md
    assertFileContent home-files/.gemini/config/skills/xlsx/SKILL.md \
      ${./skills/xlsx/SKILL.md}

    assertFileExists home-files/.gemini/config/skills/data-analysis/SKILL.md
    assertLinkExists home-files/.gemini/config/skills/data-analysis/SKILL.md
    assertFileContent home-files/.gemini/config/skills/data-analysis/SKILL.md \
      ${./skills/data-analysis/SKILL.md}

    assertFileExists home-files/.gemini/config/skills/pdf-processing/SKILL.md
    assertLinkExists home-files/.gemini/config/skills/pdf-processing/SKILL.md
    assertFileContent home-files/.gemini/config/skills/pdf-processing/SKILL.md \
      ${./skills/pdf-processing/SKILL.md}
  '';
}
