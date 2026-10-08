import { defineSandbox } from "managed-deepagents";

// A LangSmith sandbox with Google Chrome and the WebdriverIO CLI. `setup.sh`
// installs both on top of LangSmith's default template (Ubuntu 24.04) and is
// baked into a recipe snapshot at deploy time, so new threads start with a
// ready browser.
//
// No `dockerImage` bake base: MDA builds those with a 1 GiB filesystem, which
// is too small for Node plus Chrome.
export const sandbox = defineSandbox({
  // Keep the browser session around between turns of a conversation.
  idleTtlSeconds: 900,
  // Default per-command timeout, in seconds.
  defaultTimeout: 300,
});
