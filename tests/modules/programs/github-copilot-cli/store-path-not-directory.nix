{ pkgs, ... }:
let
  agentFile = pkgs.writeText "code-reviewer.agent.md" ''
    ---
    description: Invalid top-level agent file fixture.
    tools: ["*"]
    ---
  '';

  skillFile = pkgs.writeText "SKILL.md" ''
    ---
    name: invalid-top-level-skill
    description: Invalid top-level skill file fixture.
    ---
  '';
in
{
  programs.github-copilot-cli = {
    enable = true;
    agents = "${agentFile}";
    skills = "${skillFile}";
  };

  test.asserts.assertions.expected = [
    "`programs.github-copilot-cli.agents` must be a directory when set to a path"
    "`programs.github-copilot-cli.skills` must be a directory when set to a path"
  ];
}
