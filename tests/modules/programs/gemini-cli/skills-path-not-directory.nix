{
  programs.gemini-cli = {
    enable = true;
    skills = ./skills/xlsx/SKILL.md;
  };

  test.asserts.assertions.expected = [
    "`programs.gemini-cli.skills` must be a directory when set to a path"
  ];
}
