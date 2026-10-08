# Flight Scout: browser use with Managed Deep Agents

A [Managed Deep Agent](https://github.com/langchain-ai/managed-deepagents-sdk)
that compares flights on Google Flights by driving a real Chrome browser in a
LangSmith sandbox.

There is almost no code. The agent gets its browser through the sandbox and
learns to use it from two skills:

- **`sandbox/`** bakes Google Chrome and the WebdriverIO CLI into the sandbox
  snapshot.
- **`skills/browser`** teaches the agent
  [`wdio session`](https://webdriver.io/docs/session). This WebdriverIO command
  keeps a browser open between short shell commands. It also ships its own agent
  skill, which the agent loads with `wdio session skill`.
- **`skills/google-flights`** is the recipe: open a search from a plain-English
  `?q=` URL, switch to the cheapest results, and pull every result's summary
  out of the page in one `exec` call.

```text
browser-use-example/
  agent.ts                      # defineDeepAgent: name + model, no custom tools
  instructions.md               # system prompt: compare, show evidence, never book
  identity.ts                   # managed authentication
  sandbox/index.ts              # LangSmith default template (Ubuntu 24.04)
  sandbox/setup.sh              # installs Node 24 if needed, Chrome + wdio, warms up chromedriver
  skills/browser/SKILL.md       # how to use `wdio session` in this sandbox
  skills/google-flights/SKILL.md
```

## Screenshots in LangSmith

The agent takes a screenshot with `wdio session screenshot`, then opens the PNG
with Deep Agents' built-in `read_file` tool. For image files, `read_file`
returns an `image` content block instead of text. The model sees the page, and
LangSmith renders the image inline in the trace, both on the `read_file` tool
run and in the next model call's input.

## Run it

Put your keys in `.env` (never commit it). `mda deploy` forwards
`ANTHROPIC_API_KEY` to the deployment as a secret:

```bash
LANGSMITH_API_KEY=...
ANTHROPIC_API_KEY=...
```

Then:

```bash
npm install
npx mda dev      # local dev server, real LangSmith sandbox
npx mda deploy   # deploy to LangSmith
```

The first `dev` or `deploy` bakes the sandbox snapshot, which installs Chrome
and takes a few minutes. Later threads clone the snapshot and start right away.

Try prompts like:

- "Compare round-trip flights from SFO to JFK, leaving Nov 12 and returning Nov 15."
- "Cheapest nonstop from Berlin to Lisbon on Dec 4, one way. Is Dec 3 or Dec 5 cheaper?"
- "I need to be in London by 9am on Nov 21. Compare JFK and EWR departures the night before."

## Notes

- The agent compares and never books. It doesn't sign in, click through to
  checkout or enter personal data.
- Chrome runs headless as root in the sandbox, so every `open` passes
  `--no-sandbox --disable-dev-shm-usage`. The `browser` skill covers this.
- Google may serve a consent page or a bot check from some regions. The skill
  rejects consent dialogs and has the agent stop at a CAPTCHA instead of
  solving it.
