import { defineDeepAgent } from "managed-deepagents";

// No custom tools: the agent drives a headless Chrome in its LangSmith sandbox
// with the `wdio session` CLI (see `skills/browser`) and looks at screenshots
// with the built-in `read_file` tool, which returns PNGs as image blocks.
export const agent = defineDeepAgent({
  name: "flight-scout",
  // Needs ANTHROPIC_API_KEY in `.env`; `mda deploy` forwards it as a secret.
  model: "anthropic:claude-sonnet-5-5",
});
