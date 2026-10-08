{ pkgs, ... }:

{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "antigravity-cli" "";
    skills = ./skills/xlsx/SKILL.md;
  };

  test.asserts.assertions.expected = [
    "`programs.antigravity-cli.skills` must be a directory when set to a path"
  ];
}
