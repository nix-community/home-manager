{
  programs.crush = {
    enable = true;

    skillsDir = ./skills;

    settings = {
      options = {
        disabled_tools = [
          "bash"
          "sourcegraph"
        ];
        skills_paths = [
          "~/.config/crush/skills"
          "./project-skills"
        ];
        initialize_as = "AGENTS.md";
        attribution = {
          trailer_style = "co-authored-by";
          generated_with = true;
        };
        disable_provider_auto_update = true;
        disable_metrics = true;
      };

      permissions = {
        allowed_tools = [
          "view"
          "ls"
          "grep"
          "edit"
        ];
      };

      lsp = {
        go = {
          command = "gopls";
          env = {
            GOTOOLCHAIN = "go1.24.5";
          };
        };
        typescript = {
          command = "typescript-language-server";
          args = [ "--stdio" ];
        };
        nix = {
          command = "nil";
        };
      };

      mcp = {
        filesystem = {
          type = "stdio";
          command = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-filesystem"
            "/tmp"
          ];
          timeout = 120;
        };
        github = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp/";
          headers = {
            Authorization = "Bearer $(echo $GH_PAT)";
          };
        };
        streaming = {
          type = "sse";
          url = "https://example.com/mcp/sse";
          headers = {
            "API-Key" = "$(echo $API_KEY)";
          };
          disabled_tools = [ "some-tool" ];
        };
      };

      providers = {
        deepseek = {
          type = "openai-compat";
          base_url = "https://api.deepseek.com/v1";
          api_key = "$DEEPSEEK_API_KEY";
          models = [
            {
              id = "deepseek-chat";
              name = "Deepseek V3";
              cost_per_1m_in = 0.27;
              cost_per_1m_out = 1.1;
              cost_per_1m_in_cached = 0.07;
              cost_per_1m_out_cached = 1.1;
              context_window = 64000;
              default_max_tokens = 5000;
            }
          ];
        };
        custom-anthropic = {
          type = "anthropic";
          base_url = "https://api.anthropic.com/v1";
          api_key = "$ANTHROPIC_API_KEY";
          extra_headers = {
            "anthropic-version" = "2023-06-01";
          };
          models = [
            {
              id = "claude-sonnet-4-20250514";
              name = "Claude Sonnet 4";
              cost_per_1m_in = 3.0;
              cost_per_1m_out = 15.0;
              context_window = 200000;
              default_max_tokens = 50000;
              can_reason = true;
              supports_attachments = true;
            }
          ];
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/crush/crush.json
    assertFileContent home-files/.config/crush/crush.json ${./expected-config.json}

    # Verify skills directory is linked
    assertDirectoryExists home-files/.config/crush/skills
    assertLinkExists home-files/.config/crush/skills

    # Verify standalone skill file (test-skill.md)
    assertFileExists home-files/.config/crush/skills/test-skill.md
    assertFileRegex home-files/.config/crush/skills/test-skill.md "Test Skill"

    # Verify standalone skill file (standalone-skill.md)
    assertFileExists home-files/.config/crush/skills/standalone-skill.md
    assertFileRegex home-files/.config/crush/skills/standalone-skill.md "Standalone Skill"

    # Verify directory-based skill (directory-skill/)
    assertDirectoryExists home-files/.config/crush/skills/directory-skill
    assertFileExists home-files/.config/crush/skills/directory-skill/SKILL.md
    assertFileRegex home-files/.config/crush/skills/directory-skill/SKILL.md "Directory Skill"
    assertFileExists home-files/.config/crush/skills/directory-skill/README.md
  '';
}
