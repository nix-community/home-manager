{
  pkgs,
  lib,
  options,
  ...
}:

{
  programs.gemini-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "gemini-cli" "";
    defaultModel = "gemini-2.5-flash";
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
    permissions = {
      allow = [ "command(git)" ];
      deny = [ "command(rm -rf)" ];
      ask = [ "command(*)" ];
    };
  };
  test.asserts.warnings.expected = [
    "The option `programs.gemini-cli' defined in ${lib.showFiles options.programs.gemini-cli.files} has been renamed to `programs.antigravity-cli'."
  ];

  nmt.script = ''
    assertFileExists home-files/.gemini/settings.json
    assertFileContent home-files/.gemini/settings.json \
      ${./settings.json}
    assertFileExists home-files/.gemini/commands/changelog.toml
    assertFileRegex home-files/.gemini/commands/changelog.toml \
      'prompt ='
    assertFileRegex home-files/.gemini/commands/changelog.toml \
      "Adds a new entry to the project's CHANGELOG.md file."
    assertFileExists home-files/.gemini/commands/git/fix.toml
    assertFileRegex home-files/.gemini/commands/git/fix.toml \
      'prompt ='
    assertFileRegex home-files/.gemini/commands/git/fix.toml \
      'Generates a fix for a given GitHub issue.'

    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export GEMINI_MODEL="gemini-2.5-flash"'
  '';
}
