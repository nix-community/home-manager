{
  programs.codex = {
    enable = true;
    skills = ./skill-file.md;
  };

  test.asserts.assertions.expected = [
    "`programs.codex.skills` must be a directory when set to a path"
  ];
}
