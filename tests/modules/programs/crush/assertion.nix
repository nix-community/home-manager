{
  programs.crush = {
    enable = true;

    skills = {
      test = "test skill content";
    };

    skillsDir = ./skills;
  };

  test.asserts.assertions.expected = [
    "Cannot specify both `programs.crush.skills` and `programs.crush.skillsDir`"
  ];
}
