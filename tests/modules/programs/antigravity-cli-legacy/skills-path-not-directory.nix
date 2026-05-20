{
  pkgs,
  lib,
  options,
  ...
}:

{
  programs.gemini-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "gemini-cli" "";
    skills = ./skills/xlsx/SKILL.md;
  };

  test.asserts.warnings.expected = [
    "The option `programs.gemini-cli' defined in ${lib.showFiles options.programs.gemini-cli.files} has been renamed to `programs.antigravity-cli'."
  ];

  test.asserts.assertions.expected = [
    "`programs.antigravity-cli.skills` must be a directory when set to a path"
  ];
}
