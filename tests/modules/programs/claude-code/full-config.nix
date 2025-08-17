{
  programs.claude-code = {
    enable = true;

    settings = {
      theme = "dark";
      permissions = {
        allow = [
          "Bash(git diff:*)"
          "Edit"
        ];
        ask = [ "Bash(git push:*)" ];
        deny = [
          "WebFetch"
          "Bash(curl:*)"
          "Read(./.env)"
          "Read(./secrets/**)"
        ];
        additionalDirectories = [ "../docs/" ];
        defaultMode = "acceptEdits";
        disableBypassPermissionsMode = "disable";
      };
      model = "claude-3-5-sonnet-20241022";
      hooks = {
        UserPromptSubmit = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "echo 'User submitted: $CLAUDE_USER_PROMPT'";
              }
            ];
          }
        ];
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "echo 'Running bash command: $CLAUDE_TOOL_INPUT'";
              }
            ];
          }
        ];
      };
      statusLine = {
        type = "command";
        command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')] 📁 $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
        padding = 0;
      };
      includeCoAuthoredBy = false;
    };

    commands = {
      changelog = ''
        ---
        allowed-tools: Bash(git log:*), Bash(git diff:*)
        argument-hint: [version] [change-type] [message]
        description: Update CHANGELOG.md with new entry
        ---
        Parse the version, change type, and message from the input
        and update the CHANGELOG.md file accordingly.
      '';
      commit = ''
        ---
        allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
        description: Create a git commit with proper message
        ---
        ## Context

        - Current git status: !`git status`
        - Current git diff: !`git diff HEAD`
        - Recent commits: !`git log --oneline -5`

        ## Task

        Based on the changes above, create a single atomic git commit with a descriptive message.
      '';
    };

    agents = {
      code-reviewer = ''
        ---
        name: code-reviewer
        description: Specialized code review agent
        tools: Read, Edit, Grep
        ---

        You are a senior software engineer specializing in code reviews.
        Focus on code quality, security, and maintainability.
      '';

      documentation = ''
        ---
        name: documentation
        description: Documentation writing assistant
        model: claude-3-5-sonnet-20241022
        tools: Read, Write, Edit
        ---

        You are a technical writer who creates clear, comprehensive documentation.
        Focus on user-friendly explanations and examples.
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/settings.json
    assertFileContent home-files/.claude/settings.json ${./expected-settings.json}

    assertFileExists home-files/.claude/agents/code-reviewer.md
    assertFileContent home-files/.claude/agents/code-reviewer.md ${./expected-code-reviewer.md}

    assertFileExists home-files/.claude/agents/documentation.md
    assertFileContent home-files/.claude/agents/documentation.md ${./expected-documentation.md}


    assertFileExists home-files/.claude/commands/changelog.md
    assertFileContent home-files/.claude/commands/changelog.md ${./expected-changelog}

    assertFileExists home-files/.claude/commands/commit.md
    assertFileContent home-files/.claude/commands/commit.md ${./expected-commit}
  '';
}
