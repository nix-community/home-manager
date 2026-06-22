{ pkgs, ... }:

{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "antigravity-cli" "";
    defaultModel = "gemini-2.5-flash";
    settings = {
      colorScheme = "tokyo night";
      altScreenMode = "always";
      toolPermission = "proceed-in-sandbox";
      artifactReviewPolicy = "agent-decides";
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
  nmt.script = ''
    assertFileExists home-files/.gemini/antigravity-cli/settings.json
    assertFileContent home-files/.gemini/antigravity-cli/settings.json \
      ${./settings.json}
    assertFileExists home-files/.gemini/antigravity-cli/skills/changelog/SKILL.md
    assertFileRegex home-files/.gemini/antigravity-cli/skills/changelog/SKILL.md \
      'name: changelog'
    assertFileRegex home-files/.gemini/antigravity-cli/skills/changelog/SKILL.md \
      "Adds a new entry to the project's CHANGELOG.md file."
    assertFileExists home-files/.gemini/antigravity-cli/skills/git:fix/SKILL.md
    assertFileRegex home-files/.gemini/antigravity-cli/skills/git:fix/SKILL.md \
      'name: git:fix'
    assertFileRegex home-files/.gemini/antigravity-cli/skills/git:fix/SKILL.md \
      'Generates a fix for a given GitHub issue.'

    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export GEMINI_MODEL="gemini-2.5-flash"'
  '';
}
