{ config, ... }:
{
  time = "2025-09-17T02:29:29+00:00";
  condition = config.programs.opencode.enable;
  message = ''
    The opencode module now supports enhanced customization with custom commands and agents.

    You can now define custom commands and agents for opencode in two ways:

    - Inline content as strings
    - File paths to external markdown files

    Example configuration:

      programs.opencode = {
        commands = {
          # Inline content
          changelog = '''
            # Update Changelog Command
            Update CHANGELOG.md with new entries.
          ''';
          # File path
          fix-issue = ./commands/fix-issue.md;
        };

        agents = {
          # Inline content
          code-reviewer = '''
            # Code Reviewer Agent
            Specialized code review assistant.
          ''';
          # File path
          documentation = ./agents/documentation.md;
        };
      };

    Commands are stored in ~/.config/opencode/command/ and agents in ~/.config/opencode/agent/.
  '';
}
