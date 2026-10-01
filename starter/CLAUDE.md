@AGENTS.md

## Claude Code notes

- The Roblox Studio MCP server must be connected (Studio: Assistant, then
  "...", then Manage MCP Servers, then Quick connect Claude Code). Check with
  `/mcp` if Studio tools are missing, and tell the developer instead of guessing.
- Use plan mode for anything bigger than one phase, and keep the plan in the
  conversation until the developer agrees.
- Use subagents for broad exploration (finding every instance of something
  across a large place) so the main context stays on the task.
- Stop at the end of each phase with the summary from "Definition of done";
  don't chain phases without the developer playtesting in between.
