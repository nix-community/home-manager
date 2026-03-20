{
  programs.opencode = {
    enable = true;
    tools = {
      database-query = ''
        import { tool } from "@opencode-ai/plugin"

        export default tool({
          description: "Query the project database",
          args: {
            query: tool.schema.string().describe("SQL query to execute"),
          },
          async execute(args) {
            return `Executed query: ''${args.query}`
          },
        })
      '';
      api-client = ''
        import { tool } from "@opencode-ai/plugin"

        export default tool({
          description: "Make API requests to external services",
          args: {
            endpoint: tool.schema.string().describe("API endpoint to call"),
            method: tool.schema.string().describe("HTTP method"),
          },
          async execute(args) {
            return `Called ''${args.method} ''${args.endpoint}`
          },
        })
      '';
    };
  };
  nmt.script = ''
    assertFileExists home-files/.config/opencode/tool/database-query.ts
    assertFileExists home-files/.config/opencode/tool/api-client.ts
    assertFileContent home-files/.config/opencode/tool/database-query.ts \
      ${./database-query-tool.ts}
    assertFileContent home-files/.config/opencode/tool/api-client.ts \
      ${./api-client-tool.ts}
  '';
}
