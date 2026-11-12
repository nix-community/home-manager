{
  programs.pi-coding-agent = {
    enable = true;
    skills = ./skill-file.md;
  };

  test.asserts.assertions.expected = [
    "`programs.pi-coding-agent.skills` must be a directory when set to a path"
  ];
}
