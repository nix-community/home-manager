{
  programs.gemini-cli = {
    enable = true;
    settings = {
      theme = "Default";
      vimMode = true;
      preferredEditor = "nvim";
      autoAccept = true;
    };
    commands = {
      changelog = {
        prompt = ''
          Your task is to parse the `<version>`, `<change_type>`, and `<message>` from their input and use the `write_file` tool to correctly update the `CHANGELOG.md` file.
        '';
        description = "Adds a new entry to the project's CHANGELOG.md file.";
      };
      "git/fix" = {
        prompt = "Please analyze the staged git changes and provide a code fix for the issue described here: {{args}}.";
        description = "Generates a fix for a given GitHub issue.";
      };
    };
  };
  nmt.script = ''
    assertFileExists home-files/.gemini/settings.json
    assertFileContent home-files/.gemini/settings.json \
      ${./settings.json}
    assertFileContent home-files/.gemini/commands/changelog.toml \
      ${./changelog.toml}
    assertFileContent home-files/.gemini/commands/git/fix.toml \
      ${./fix.toml}
  '';
}
