{
  pkgs,
  lib,
  options,
  ...
}:

let
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

  test.asserts.warnings.expected = [
    "The option `programs.gemini-cli' defined in ${lib.showFiles options.programs.gemini-cli.files} has been renamed to `programs.antigravity-cli'."
  ];

  nmt.script = ''
    assertFileExists home-files/.gemini/skills/external-skill/SKILL.md
    assertLinkExists home-files/.gemini/skills/external-skill/SKILL.md
    assertFileContent home-files/.gemini/skills/external-skill/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
