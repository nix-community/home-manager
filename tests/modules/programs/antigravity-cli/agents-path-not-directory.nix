{ pkgs, ... }:

{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "antigravity-cli" "";
    agents = ./agents/code-reviewer/agent.md;
  };

  test.asserts.assertions.expected = [
    "`programs.antigravity-cli.agents` must be a directory when set to a path"
  ];
}
