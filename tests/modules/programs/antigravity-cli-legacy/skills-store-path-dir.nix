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
  src = pkgs.writeTextDir "skills/external-skill/SKILL.md" ''
    # External Skill
  '';
in
{
  programs.gemini-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "gemini-cli" "";
    skills = "${src}/skills";
  };

  test.asserts.warnings.expected = map renamedWarning [
    "skills"
    "package"
    "enable"
  ];

  nmt.script = ''
    assertFileExists home-files/.gemini/skills/external-skill/SKILL.md
    assertLinkExists home-files/.gemini/skills/external-skill/SKILL.md
    assertFileContent home-files/.gemini/skills/external-skill/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
