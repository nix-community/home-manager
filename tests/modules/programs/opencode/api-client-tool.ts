import { tool } from "@opencode-ai/plugin"

export default tool({
  description: "Make API requests to external services",
  args: {
    endpoint: tool.schema.string().describe("API endpoint to call"),
    method: tool.schema.string().describe("HTTP method"),
  },
  async execute(args) {
    return `Called ${args.method} ${args.endpoint}`
  },
})
