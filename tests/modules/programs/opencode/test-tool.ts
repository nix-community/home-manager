import { tool } from "@opencode-ai/plugin"

export default tool({
  description: "Test tool for unit testing",
  args: {
    input: tool.schema.string().describe("Test input parameter"),
  },
  async execute(args) {
    return `Processed: ${args.input}`
  },
})
