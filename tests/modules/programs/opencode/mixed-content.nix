{
  programs.opencode = {
    enable = true;
    commands = {
      inline-command = ''
        # Inline Command
        This command is defined inline.
      '';
      path-command = ./test-command.md;
    };
    agents = {
      inline-agent = ''
        # Inline Agent
        This agent is defined inline.
      '';
      path-agent = ./test-agent.md;
    };
    tools = {
      inline-tool = ''
        import { tool } from "@opencode-ai/plugin"

        export default tool({
          description: "Inline tool definition",
          args: {
            input: tool.schema.string().describe("Test input"),
          },
          async execute(args) {
            return `Processed: ''${args.input}`
          },
        })
      '';
      path-tool = ./test-tool.ts;
    };
    skills = {
      inline-skill = ''
        ---
        name: inline-skill
        description: An inline skill definition
        ---

        ## What I do
        This skill is defined inline.
      '';
      path-skill = ./git-release-SKILL.md;
      dir-skill = ./skill-dir/data-analysis;
    };
    themes = {
      inline-theme = {
        name = "inline-theme";
        colors = {
          primary = "#000000";
          secondary = "#ffffff";
        };
      };
      path-theme = ./my-theme.json;
    };
  };
  nmt.script = ''
    # Commands
    assertFileExists home-files/.config/opencode/command/inline-command.md
    assertFileExists home-files/.config/opencode/command/path-command.md

    assertFileContent home-files/.config/opencode/command/path-command.md \
      ${./test-command.md}

    # Agents
    assertFileExists home-files/.config/opencode/agent/inline-agent.md
    assertFileExists home-files/.config/opencode/agent/path-agent.md

    assertFileContent home-files/.config/opencode/agent/path-agent.md \
      ${./test-agent.md}

    # Tools
    assertFileExists home-files/.config/opencode/tool/inline-tool.ts
    assertFileExists home-files/.config/opencode/tool/path-tool.ts

    assertFileContent home-files/.config/opencode/tool/path-tool.ts \
      ${./test-tool.ts}

    # Skills
    assertFileExists home-files/.config/opencode/skill/inline-skill/SKILL.md
    assertFileExists home-files/.config/opencode/skill/path-skill/SKILL.md
    assertFileExists home-files/.config/opencode/skill/dir-skill/SKILL.md
    assertFileExists home-files/.config/opencode/skill/dir-skill/notes.txt

    assertFileContent home-files/.config/opencode/skill/path-skill/SKILL.md \
      ${./git-release-SKILL.md}
    assertFileContent home-files/.config/opencode/skill/dir-skill/SKILL.md \
      ${./skill-dir/data-analysis/SKILL.md}

    # Themes
    assertFileExists home-files/.config/opencode/themes/inline-theme.json
    assertFileExists home-files/.config/opencode/themes/path-theme.json

    assertFileContent home-files/.config/opencode/themes/path-theme.json \
      ${./my-theme.json}

    # Verify inline-theme has the schema
    assertFileContains home-files/.config/opencode/themes/inline-theme.json \
      '"$schema": "https://opencode.ai/theme.json"'
  '';
}
