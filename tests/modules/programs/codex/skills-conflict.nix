{
  programs.codex = {
    enable = true;
    skills = {
      inline-skill = "Test";
    };
    skillsDir = ./skills-dir;
  };

  test.asserts.assertions.expected = [
    "Cannot specify both `programs.codex.skills` and `programs.codex.skillsDir`"
  ];
}
