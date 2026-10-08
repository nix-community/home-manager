{
  pkgs,
  lib,
  options,
  ...
}:

let
  renamedWarning =
    name:
    "The option `programs.gemini-cli.${name}' defined in ${
      lib.showFiles (
        lib.getAttrFromPath [
          "programs"
          "gemini-cli"
          name
          "files"
        ] options
      )
    } has been renamed to `programs.antigravity-cli.${name}'.";
in
{
  programs.gemini-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "gemini-cli" "";
    skills = ./skills;
  };

  test.asserts.warnings.expected = map renamedWarning [
    "skills"
    "package"
    "enable"
  ];

  nmt.script = ''
    assertFileExists home-files/.gemini/skills/xlsx/SKILL.md
    assertLinkExists home-files/.gemini/skills/xlsx/SKILL.md
    assertFileContent home-files/.gemini/skills/xlsx/SKILL.md \
      ${./skills/xlsx/SKILL.md}

    assertFileExists home-files/.gemini/skills/data-analysis/SKILL.md
    assertLinkExists home-files/.gemini/skills/data-analysis/SKILL.md
    assertFileContent home-files/.gemini/skills/data-analysis/SKILL.md \
      ${./skills/data-analysis/SKILL.md}

    assertFileExists home-files/.gemini/skills/pdf-processing/SKILL.md
    assertLinkExists home-files/.gemini/skills/pdf-processing/SKILL.md
    assertFileContent home-files/.gemini/skills/pdf-processing/SKILL.md \
      ${./skills/pdf-processing/SKILL.md}
  '';
}
