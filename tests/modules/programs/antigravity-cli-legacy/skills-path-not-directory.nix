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
    skills = ./skills/xlsx/SKILL.md;
  };

  test.asserts.warnings.expected = map renamedWarning [
    "skills"
    "package"
    "enable"
  ];

  test.asserts.assertions.expected = [
    "`programs.antigravity-cli.skills` must be a directory when set to a path"
  ];
}
