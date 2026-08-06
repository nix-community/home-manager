{
  programs.cursor-agent = {
    enable = true;
    package = null;
    rules = {
      code-style = "test";
    };
    rulesDir = ./rules;
    agents = {
      test-agent = "test";
    };
    agentsDir = ./agents;
    commands = {
      test-command = "test";
    };
    commandsDir = ./commands;
    skills = {
      test-skill = "test";
    };
    skillsDir = ./skills;
  };

  test.asserts.assertions.expected = [
    "Cannot specify both `programs.cursor-agent.rules` and `programs.cursor-agent.rulesDir`"
    "Cannot specify both `programs.cursor-agent.agents` and `programs.cursor-agent.agentsDir`"
    "Cannot specify both `programs.cursor-agent.commands` and `programs.cursor-agent.commandsDir`"
    "Cannot specify both `programs.cursor-agent.skills` and `programs.cursor-agent.skillsDir`"
  ];
}
