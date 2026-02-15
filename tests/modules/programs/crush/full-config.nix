{
  programs.crush = {
    enable = true;

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
              context_window = 64000;
            }
          ];
        };
      };
    };

    skills = {
      pdf = ''
        ---
        name: pdf
        description: PDF processing
        ---
        PDF tools
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/crush/crush.json
    assertFileContent home-files/.config/crush/crush.json ${./expected-full-config.json}

    assertFileExists home-files/.config/crush/skills/pdf.md
    assertFileRegex home-files/.config/crush/skills/pdf.md "PDF tools"
  '';
}
