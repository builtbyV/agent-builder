# Agent Creation Guide

## Commands

```bash
cp agent.stub <name>.js                          # always copy, never edit agent.stub
node <name>.js --yolo                             # run default task (if defaultTask is set)
node <name>.js "task"                             # preview tool calls (safe)
node <name>.js "task" --yolo                      # execute tools (overrides defaultTask)
node <name>.js "task" --model deepseek-r1 --yolo  # specific Ollama model
node <name>.js "task" --model openai:gpt-5-mini --yolo  # cloud provider
node <name>.js "task" --max-turns 10 --yolo       # override 5-turn default
node <name>.js "task" --cwd ./workspace --yolo    # confine file ops to dir
node <name>.js "task" --allow-host api.github.com --yolo  # extend network allowlist
```

Provider prefixes: `ollama:`, `openai:`, `anthropic:`, `gemini:` (or use `--provider`).
API keys: `--openai-key sk-...` / `--anthropic-key` / `--gemini-key`, or env vars, or `.env` in cwd. Use `--save-keys` to persist.

## Gotchas

- **Never modify `agent.stub` directly** — always `cp` first. The stub is the shared template.
- **`safePath` confines all file ops to `--cwd`** — writing outside the workspace directory errors. Don't try absolute paths.
- **4KB output truncation** — tool results default to 4096 chars (CONFIG.maxToolOutputChars). Pass a larger `max_bytes` to `read_file`/`fetch_url`/`scrape_page` to override. Split large reads into chunks or filter before returning.
- **Ollama must be running** — start with `ollama serve` or the agent gets `ECONNREFUSED`. Check with `curl http://localhost:11434`.
- **`maxTurns` defaults to 5** — complex multi-step tasks need `--max-turns 10` or higher via CLI flag.
- **`define_tool` runs in a VM sandbox** — dynamic tools cannot `require()` modules. They get: `fetch`, `file.read/write/list`, `args`, `AppError`, `assertString`, `truncate`.
- **Without `--yolo`, nothing executes** — tool calls are only previewed. Users must re-run with `--yolo` to execute.
- **JSON repair is lenient but not magic** — the stub fixes trailing commas and unquoted keys, but double-encoded JSON or nested unescaped quotes still break.
- **The scaffold says "do not ask the user to clarify"** — agent instructions should pick sensible defaults and state assumptions, not ask-for-more-info.
- **Respect cancellation** — long-running tools should check `ctx.signal.aborted` and bail early.
- **Always call `finish_task` when done** — local models often ramble past the answer or loop. `finish_task` emits `<<AGENT_DONE>>` which cleanly stops the agent loop. Set `defaultTask` and encode `finish_task` in the system prompt.
- **Turn-aware prompting** — full tool instructions are sent on turn 1 only. Turn 2+ gets a brief reminder to conserve context for local models.
- **Tools run in parallel** — all tool calls in a single response execute concurrently via `Promise.all`. Independent tools don't wait for each other.
- **Error recovery hints** — tool failures include actionable hints (e.g., ENOENT → "Use list_files to check what exists"). The model sees `[OK]`/`[FAIL]`/`[EMPTY]` prefixes in tool results.
- **Context compression** — after 6+ messages, older conversation history is summarized to free context window for local models.
- **`spawn_agent` decomposes big tasks** — local models choke when context fills up. Use `spawn_agent` to split work into focused subtasks, each with a fresh context and 2-3 turn budget. The parent orchestrates; children do the heavy lifting. Max nesting depth: 3.
- **Skills are progressive-disclosure add-ons** — drop `SKILL.md` bundles into `./skills/<name>/` and the harness auto-lists them (name + description) in the system prompt at turn 1. The agent calls `load_skill` to open one, then `read_file` for any referenced scripts/references/assets. Bodies never load until the agent opts in, so skills cost ~100 tokens each at idle. Install with `npx skills add <source>` or `add-skill.sh`.
- **Network allowlist** — HTTP tools (`fetch_url`, `scrape_page`, `download_file`, `discover_skills`) are gated by `CONFIG.networkAllowlist`. Default: `duckduckgo.com`, `html.duckduckgo.com` (so `search_web` works out of the box). Extend per-run with `--allow-host <host>` (repeatable) or the `AGENT_BUILDER_ALLOW_HOSTS` env var (comma-separated). Use `*.example.com` for subdomain wildcards. Empty array = allow all.
- **Sandboxed execution** — `run_in_container` runs a shell command inside an OCI container via Apple's `container` CLI (preferred) or `docker` (fallback). Default `--network none` and no writable mounts. Use it for untrusted scripts from skills, runtimes not installed locally, or anything that shouldn't touch the host. Load the bundled `apple-container` skill with `load_skill` for install/setup.
- **MCP (Model Context Protocol) servers** — drop a `./mcp.json` (or set `CONFIG.mcpServers`) and the harness spawns each server at startup, lists its tools, and registers them as `<server>_<tool>`. stdio transport only; pure Node, no new deps. See the MCP section below.
- **`read_file` supports line-numbered windowed reads** — pass `start_line` (and optional `end_line`, defaults to a 100-line window) to get exactly the region the agent needs with `   47: ` numbered prefixes. Use this before `patch_file` so the line numbers the agent targets are the ones the tool sees.
- **`patch_file` replaces line ranges atomically** — `{path, start_line, end_line, replacement}` is the surgical edit primitive. Preferred over `write_file` for anything larger than a trivial file because tokens scale with the change, not the file. No built-in linter — compose with `run_in_container` or a skill-provided checker if you need one.
- **Long-running projects** — for work spanning multiple agent runs, use the four-file pattern (`feature_list.json`, `progress.md`, `init.sh`, git) documented in the Long-Running Projects section. It's a convention, not harness code, and it's what keeps multi-session work coherent.
- **Scheduling / triggers** — `automation/invoke-agent.sh` is the universal entrypoint for any scheduler (launchd, cron, Apple Shortcuts). Templates under `automation/launchd/` cover timer, calendar, and folder-watch triggers. The `inbox/` → agent → `outbox/` pattern makes iMessage / Siri / NFC / share-sheet / webhook all look the same to the agent. See `automation/README.md` for recipes.

## Workflow

When a user asks to create an agent:

1. **Extract core intent** — purpose, tools needed, output format, what "done" looks like. Look for both explicit requirements and implicit needs. Consider any project-specific context (existing AGENTS.md files, coding standards, established patterns) to ensure the agent aligns with the project. For code review agents, assume the user means *recently written code*, not the whole codebase, unless stated otherwise.
2. **Design expert persona** — concrete role + domain (e.g., "senior security researcher specializing in OWASP top 10"), not generic "helpful assistant"
3. **Name it** — lowercase hyphenated, 2-4 words: `csv-data-analyst`, `tech-news-researcher`. Avoid "helper", "assistant", "bot"
4. **Check model** — run `ollama list` to see installed models, and check system resources. Pick a model that fits the agent's needs and the machine's RAM (see "Model Selection" below)
5. **Copy stub** — `cp agent.stub <identifier>.js`
6. **Fill the scaffold** — in `AGENT_INSTRUCTION`, replace every `[BRACKETED]` field with concrete values from steps 1-2. Do this before anything else
7. **Set `defaultTask`** — in CONFIG, set `defaultTask` to the agent's primary purpose (e.g., `'Summarize all files in the working directory'`). This lets users run `node <name>.js --yolo` without repeating what the system prompt already describes. Users can still override: `node <name>.js "custom task" --yolo`
8. **Replace `example_tool`** — implement domain-specific tools following the pattern in "Tool Implementation Pattern" below
9. **Test** — `node <name>.js --yolo` to run the default task, or `node <name>.js "custom task"` to preview a custom one

### Design do/don't

Do:
```
You are a senior data engineer specialized in ETL pipeline debugging.

Your approach:
1. Read the pipeline config and identify the failing stage
2. Inspect input data samples for schema mismatches
3. Trace the transform chain to find where data is lost
4. Write a fix and validate against sample data

Output format:
- Diagnosis as markdown with code snippets
- Fixed config saved to ./output/
```

Don't:
```
You are a helpful agent that assists users with data tasks.

Your approach:
1. Understand the request
2. Do the work
3. Return results
```

The first gives the agent a decision-making framework. The second gives it nothing.

### Architecting the System Prompt

The system prompt is the agent's complete operational manual. It should make the agent an autonomous expert that handles its designated tasks with minimal additional guidance.

Write the `AGENT_INSTRUCTION` in second person ("You are...", "You will..."). Incorporate any specific requirements or preferences the user mentioned. Build it to include:

1. **Behavioral boundaries** — what the agent should and shouldn't do. Name specific files, paths, or actions that are off-limits.
2. **Domain methodology** — concrete step-by-step approach for the domain, not generic "analyze then respond." What does a real expert in this field actually do first, second, third?
3. **Edge case handling** — anticipate where things go wrong. "If the CSV has no headers, treat the first row as data and generate column names." "If a source URL returns 403, skip it and note the gap."
4. **Self-verification** — the agent should check its own work before delivering. "After writing the report, re-read it and verify all citations have matching sources."
5. **Escalation / fallback** — what to do when tools fail or results are ambiguous. "If search returns no results, broaden the query. If still empty, state what was attempted."
6. **Output contract** — exact format, file paths, and structure. "Save as `./output/<topic>_report.md` with sections: Executive Summary, Findings, Sources."

Every instruction should trace to a decision the agent would otherwise get wrong.

## The Scaffold

The `AGENT_INSTRUCTION` in the stub ships this template. Replace ALL `[BRACKETED]` fields before calling any tools:

```
You are a [ROLE/TYPE] specialized in [DOMAIN/EXPERTISE].

Your approach:
1. [First step for this type of agent]
2. [Second step in the workflow]
3. [Continue with domain-specific steps]
4. [Final output/verification step]

Output format:
- [What format: Markdown, JSON, code files, etc.]
- [What to include: sections, fields, structure]
- [Where to save: ./output/, ./reports/, etc.]

Focus on:
- [Key quality criteria for this domain]
- [Important considerations]
- [Specific requirements]
```

### First-Turn Protocol (MUST DO)

The agent's first response must follow this sequence:
1. **Agent Setup** — rewrite the scaffold with concrete values
2. **Plan** — short bullet list of actions and which tools to call
3. **Execute** — call tools using strict JSON
4. **Deliver** — call `finish_task` with a summary and list of created files

## Tool Implementation Pattern

Replace `example_tool` with domain tools. Every tool follows this shape:

```javascript
async tool_name(args, ctx) {
  const { param1, param2 = 'default' } = args || {};
  assertString(param1, 'param1');
  try {
    const result = await doWork(param1, param2);
    return truncate(result);
  } catch (error) {
    throw new AppError(`Tool failed: ${error.message}`);
  }
}
```

### Domain Tool Signatures by Agent Type

**Research**: `web_search(query, max_results)`, `summarize_article(url, max_words)`, `compile_report(topic, sources, format)`
**Coding**: `analyze_code(path, language)`, `generate_tests(code, framework)`, `refactor_code(path, patterns)`
**Data**: `load_data(path, format)`, `analyze_trends(data, metrics)`, `generate_visualization(data, chart_type, output_path)`
**Knowledge**: `ingest_source(title, content, tags)`, `read_manifest(filter)`, `mark_compiled(file)`, `search_context(query)`, `save_learning(content, category)`, `read_section(path, heading?)`
**Orchestration**: `spawn_agent(task, instruction?, max_turns?)`, `finish_task(summary, files_created?)`

Use `verb_noun` naming. Each tool does one thing. All paths go through `safePath(ctx.cwd, path)`.

### Dynamic Tool Creation

Agents can create tools at runtime when a built-in tool doesn't exist:

```javascript
<<tool:define_tool {"name": "call_api", "code": "const response = await fetch(args.endpoint, { method: args.method || 'GET', headers: args.headers || {} }); return `Status: ${response.status}\\n${await response.text()}`;"}>
```

Dynamic tools run in a sandbox — they get `fetch`, `file.read/write/list`, `args`, and the helper functions, but cannot `require()` modules.

## Agent Definition Format

When producing a cataloged agent definition, output:

```json
{
  "identifier": "A unique, descriptive identifier using lowercase letters, numbers, and hyphens (e.g., 'test-runner', 'api-docs-writer', 'code-formatter')",
  "whenToUse": "A precise, actionable description starting with 'Use this agent when...' that clearly defines triggering conditions and use cases, with examples showing Agent tool invocation",
  "systemPrompt": "The complete AGENT_INSTRUCTION content, written in second person ('You are...', 'You will...'), structured for maximum clarity"
}
```

### Writing whenToUse

Start with "Use this agent when..." and include 2-3 examples showing an AI assistant invoking the agent. Use the commentary pattern so the assistant knows *why* to launch it:

**Reactive example** (user explicitly asks):
```
user: "Analyze this CSV and find outliers"
assistant: [uses Agent tool to launch csv-data-analyst with the file path]
<commentary>
The user is asking for data analysis — use the csv-data-analyst agent.
</commentary>
```

**Proactive example** (agent fires without being asked):
```
user: "Write a function that validates email addresses"
assistant: [writes the function]
<commentary>
Since a significant piece of code was written, use the test-runner agent
to verify it works.
</commentary>
assistant: [uses Agent tool to launch test-runner]
```

**Critical:** In examples, the assistant must use the Agent tool to launch the agent — not respond to the task directly itself. The whenToUse teaches the assistant *when to delegate*, not when to do the work inline.

If the agent should be used proactively (auto-test, auto-lint, auto-review), the whenToUse MUST include proactive examples — otherwise the assistant won't know to invoke it unprompted.

## Complete Examples

### Research Agent
```javascript
const AGENT_INSTRUCTION = `
You are a senior technology analyst specializing in emerging AI trends.

Your approach:
1. Search for recent authoritative sources (last 6 months)
2. Cross-reference claims across 3+ sources
3. Synthesize into an executive summary with citations
4. Save the report as markdown
5. Call finish_task with a summary of findings

Output format:
- Markdown report with sections: Summary, Key Findings, Sources
- Save to ./output/<topic>_report.md

Focus on:
- Recency and source authority
- Actionable insights over raw information
- Clearly flagging speculation vs established fact
`;
```

### Code Assistant Agent
```javascript
const AGENT_INSTRUCTION = `
You are a senior software engineer specializing in code quality and architecture.

When working with code:
1. First analyze the existing structure and identify patterns
2. Identify anti-patterns, security issues, and performance bottlenecks
3. Suggest improvements with explanations of why
4. Generate tests for critical paths
5. If refactoring, verify behavior is preserved by tracing sample inputs
6. Call finish_task with findings and files created

Output format:
- Inline comments for specific issues
- Summary report saved to ./output/review.md
- Generated tests saved alongside source files
`;
```

## Safety & Sandboxing

The harness gives agents two layers of protection for anything touching the outside world: a **network allowlist** for HTTP tools and a **container sandbox** for shell execution. Neither is bulletproof — they raise the cost of accidents and soft-constrain what an autonomous agent can do.

### Network allowlist

`CONFIG.networkAllowlist` controls which hosts the user-URL tools (`fetch_url`, `scrape_page`, `download_file`, `discover_skills`) may contact. `search_web` is pinned to DuckDuckGo and is not gated separately.

**Defaults** (minimal — only what built-in search needs):

```
duckduckgo.com
html.duckduckgo.com
```

**Extend per run** (no stub edit required):

```bash
# One-off: add a single host on the command line
node agent.js "Read the GitHub API" --allow-host api.github.com --yolo

# Multiple hosts
node agent.js "Scrape Wikipedia" --allow-host en.wikipedia.org --allow-host commons.wikimedia.org --yolo

# Via environment (comma-separated)
AGENT_BUILDER_ALLOW_HOSTS=api.github.com,raw.githubusercontent.com node agent.js "..." --yolo

# Wildcards: *.example.com matches all subdomains
node agent.js "..." --allow-host "*.github.com" --yolo
```

**Extend per agent** (hardcode into the agent file after `cp agent.stub`):

```javascript
// Near the top of your agent.js, in CONFIG:
networkAllowlist: [
  'duckduckgo.com',
  'html.duckduckgo.com',
  'api.github.com',          // research agents pulling repo info
  'raw.githubusercontent.com', // fetching SKILL.md from GitHub
  '*.arxiv.org',             // science/ML research agents
  'api.openweathermap.org',  // domain-specific APIs
],
```

**Typical additions by agent type:**

| Agent type | Hosts to add |
|---|---|
| **Research / news** | `en.wikipedia.org`, `arxiv.org`, `*.reuters.com`, chosen news sources |
| **Code / docs** | `api.github.com`, `raw.githubusercontent.com`, `docs.python.org`, `developer.mozilla.org` |
| **Knowledge / RAG** | Only your own source domains — avoid wildcards |
| **Data / API** | The specific API host only (`api.openweathermap.org`, etc.) |

**Disable entirely** (not recommended) by setting `networkAllowlist: []` — matches legacy behavior where any host is reachable.

### Container sandbox (`run_in_container`)

For shell execution, the harness uses Apple's native `container` CLI on macOS Apple Silicon (preferred — zero deps, lightweight VM per container) or `docker` (fallback). The tool refuses cleanly if neither is installed.

**Defaults are deny-first:**

- `--network none` — no egress from the container. Opt in with `network: "bridge"`.
- No writable host mounts unless the agent explicitly passes them.
- Host mount paths pass through `safePath`, so `mounts: ["../../etc/passwd:..."]` is rejected the same way `write_file` rejects it.
- 30 s timeout (override with `timeout_ms` up to 10 min).

**Setup** — the repo ships a minimal `apple-container` skill at `./skills/apple-container/SKILL.md`. Load it from an agent to get install and troubleshooting commands:

```
<<tool:load_skill {"name":"apple-container"}>>
```

**Invocation example:**

```
<<tool:run_in_container {
  "image": "python:3.12-slim",
  "command": "python /data/extract.py /data/input.pdf /data/out.json",
  "mounts": ["./data:/data"],
  "network": "none",
  "timeout_ms": 60000
}>>
```

**When to reach for `run_in_container`:**

- A skill bundles scripts that shouldn't run with the agent's full host privileges
- The task needs a runtime (Python, Node, Go, specific CLI) not installed locally
- The agent is doing parsing / extraction / linting on untrusted input

### Further reading: stronger isolation

`run_in_container` + the allowlist cover most practical cases. If you need stricter guarantees — per-capability permission models, CPU/memory quotas enforced in-process, JS-level isolation without Docker — look at:

- **[secure-exec](https://secureexec.dev)** (Rivet) — TypeScript library for running Node / JS code in V8 isolates with fs + network permission callbacks. npm dep; breaks the zero-dep philosophy, so fork the stub or wrap it in a separate tool rather than pulling it into the canonical harness.
- **[just-bash](https://github.com/vercel-labs/just-bash)** (Vercel Labs) — in-memory bash environment in TS. Useful when you want to emulate bash inside the agent rather than shell out. Same dep tradeoff.
- **OpenShell** — k3s-on-Docker security gateway; heavier, for production multi-tenant deployments, not single-agent use.

The stub intentionally stops at `container` + allowlist. Swap one of the above in if the threat model demands it.

## MCP (Model Context Protocol)

MCP gives agents **live capabilities** — tools served by running server processes (filesystem, github, postgres, slack, puppeteer, sequential-thinking, etc.). This complements skills: skills teach methodology (static), MCP supplies capability (dynamic).

The stub implements a minimal MCP **client** over stdio transport. No new dependencies: pure `child_process.spawn` + JSON-RPC 2.0.

### Configuration

Two options — pick whichever fits.

**Option A — `./mcp.json` in the cwd** (auto-discovered):

```json
{
  "servers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "ghp_…" }
    }
  }
}
```

**Option B — inline in the agent file** (edit `CONFIG.mcpServers`):

```javascript
const CONFIG = {
  // ...
  mcpServers: {
    filesystem: { command: "npx", args: ["-y", "@modelcontextprotocol/server-filesystem", "."] },
    github: { command: "npx", args: ["-y", "@modelcontextprotocol/server-github"], env: { GITHUB_TOKEN: process.env.GITHUB_TOKEN } }
  },
};
```

`CONFIG.mcpServers` wins if set; otherwise `./mcp.json` is loaded. Either `{servers:{...}}` or `{mcpServers:{...}}` wrappers work in the JSON file.

### How it looks to the agent

At startup the harness spawns each server, sends the handshake, pulls `tools/list`, and registers every remote tool as `<serverKey>_<toolName>` in the same `ToolRegistry` as built-ins. Both the turn-1 system prompt and every subsequent turn include a compact block:

```
MCP tools (call by name; use describe_mcp_tool for full schema):
- filesystem_read_text_file: Read a text file
- filesystem_list_directory: List entries in a directory
- github_create_issue: Create an issue on a repository
- ...
```

Each tool's TOOL_DOCS entry includes parameter names derived from the remote JSONSchema (`args: {path}`, `args: {owner, repo, title, body?}`) — enough for the LLM to call without a schema round-trip. For complex tools, the agent can `describe_mcp_tool({name: "github_create_issue"})` to get the full schema on demand.

### When to reach for MCP vs `define_tool` vs a skill

| Need | Pick |
|---|---|
| Repeatable methodology, prose-heavy | **skill** |
| One-off JS/TS logic the agent creates at runtime | **`define_tool`** |
| Access to an external service (filesystem, DB, GitHub, Slack, browser) | **MCP** |
| Long-running connection, server-side state, many related tools | **MCP** |

### Interaction with the network allowlist

MCP tools make their **own** network calls from their own child processes — they don't go through `fetch_url`, so `CONFIG.networkAllowlist` does not gate them. If you want to restrict an MCP server's network access, run it via `run_in_container` or pick a server that respects allowlist env vars. The allowlist still gates the agent's direct `fetch_url`/`scrape_page`/`download_file`/`discover_skills` calls as before.

### Lifecycle

- Servers are spawned in parallel at `runAgent` startup (`Promise.allSettled` — one bad server doesn't block others)
- Handshake timeout is 15 s; per-tool-call timeout is 60 s (tune via `CONFIG.mcpConnectTimeoutMs` / `mcpCallTimeoutMs`)
- All children are killed via `SIGTERM` in a `finally` block when the agent exits (success, failure, or throw)
- Server stderr is piped to the harness at `LOG_LEVEL=debug`
- Server-initiated notifications (e.g., `listChanged`) are logged and ignored — cached tool list does not refresh mid-run

### Scope — what is NOT implemented

Kept out of the stub to keep it readable and dep-free. Fork if you need them:

- **Streamable-HTTP transport** (remote MCP servers) — currently stdio only
- **Resources / prompts** primitives — only `tools/*` is wired
- **Authentication flows** (OAuth-style) — pass secrets via `env` in the server config
- **Sampling** (server asking the client's LLM to generate) — out of scope for this harness
- **Notifications re-subscription** — list is cached once at startup

### Building MCP servers

See `/Users/vps/desktop/dev/mcps/.claude/skills/mcp-builder/` (or the official [mcp-builder skill](https://github.com/modelcontextprotocol)) for the full server-authoring guide (Zod/Pydantic schemas, pagination conventions, tool annotations). Build one; drop it into `mcp.json`; the harness consumes it automatically.

## Skills (Add-on Capabilities)

### Overview

A **skill** is an [Anthropic-style](https://agentskills.io) `SKILL.md` bundle — a folder with YAML frontmatter (`name`, `description`) plus instructions and optional scripts/references/assets. The harness treats skills as **add-ons the agent can pull on demand** when the task enters a domain the skill covers. The agent's persona stays in `AGENT_INSTRUCTION`; skills layer on top.

The contract uses progressive disclosure:

| Level | What loads | When |
|---|---|---|
| 1 | `name` + `description` of every local skill | Auto-injected into the turn-1 system prompt |
| 2 | Full `SKILL.md` body | Agent calls `load_skill` |
| 3 | Referenced files (`scripts/`, `references/`, `assets/`) | Agent calls `read_file` on demand |

### Directory Layout

```
<cwd>/
└── skills/
    ├── pdf-extraction/
    │   ├── SKILL.md           # required: YAML frontmatter + body
    │   ├── scripts/           # optional: referenced by the body
    │   └── references/        # optional: reference docs
    └── code-review/
        └── SKILL.md
```

Minimum `SKILL.md`:

```markdown
---
name: pdf-extraction
description: Extract text and form fields from PDFs. Use when the user provides a PDF path.
---

# PDF Extraction

Your steps:
1. Run `scripts/extract.py <input.pdf> <output.json>`
2. Read the JSON and summarise fields in markdown
```

### Using Skills from an Agent

Three tools:

- **`list_skills`** — returns local name + description. Cheap; call it any time to refresh the menu.
- **`load_skill {name}`** — returns the full `SKILL.md` body. Relative links resolve under `./skills/<name>/`, so use `read_file` with paths like `skills/pdf-extraction/references/FORMS.md`.
- **`discover_skills {url}`** — read-only listing of a remote `/.well-known/agent-skills/index.json`. Installation is **not** done by the stub; use `npx skills add <url>` or `add-skill.sh` to pull a skill into `./skills/`.

The harness auto-injects Level-1 metadata into the system prompt, so the agent sees skills without calling `list_skills` first. If a skill clearly matches the task, instruct the agent to `load_skill` before acting on that domain.

### Installing Skills

The stub stays dependency-free; skill installation is a separate step. Options:

```bash
# Vercel-labs CLI (project-scoped)
npx skills add vercel-labs/agent-skills --skill frontend-design -a universal

# Local helper (from github.com/builtbyV/agent-builder)
bash add-skill.sh anthropics/skills/skills/docx

# Manual — works with any SKILL.md
mkdir -p skills/my-skill && cp /path/to/SKILL.md skills/my-skill/
```

Any skill file matching `./skills/<name>/SKILL.md` with a non-empty `description` becomes discoverable on the next run.

### Authoring Skills (`extract_skill`)

An agent can capture its own successful methodology as a draft SKILL.md by calling `extract_skill` near the end of a run. This closes the loop: the same agent that consumes skills via `load_skill` produces them via `extract_skill`.

The tool requires structure — it does not infer. The agent must supply:

| Field | Required | Notes |
|---|---|---|
| `name` | Yes | `kebab-case`, 1-64 chars, agentskills.io-compliant |
| `description` | Yes | One-line — goes into frontmatter for Level-1 disclosure |
| `when_to_use` | Yes | Trigger phrase paragraph. Starts with "Use when..." |
| `steps[]` | Yes | Each step MUST include `success_criteria`. Optional: `title`, `actions` (string or array), `artifacts`, `rules` |
| `goal` | No | Overall outcome statement |
| `inputs[]` | No | `[{name, description}]` — arguments the skill takes |
| `rules[]` | No | Hard constraints |

Drafts are written to `./skills/drafts/<name>/SKILL.md`. The `drafts` folder is visible in Finder / `ls` so non-technical users can browse and read drafts, but `discoverLocalSkills` explicitly skips it so drafts do NOT pollute the turn-1 system prompt until promoted:

```bash
# Review (or open in any editor / file browser)
cat skills/drafts/my-skill/SKILL.md

# Promote
mv skills/drafts/my-skill skills/my-skill
```

**When an agent should call `extract_skill`:**

Encode in the system prompt only when the agent performs genuinely repeatable work. Not every run warrants a skill; bad drafts pollute the registry. A reasonable trigger:

```
After finish_task, if the task followed a methodology that would help on similar
future requests (distinct steps, clear success criteria, reusable inputs), call
extract_skill with the structured steps. Skip for one-off or ambiguous work.
```

### When to Use Skills vs AGENT_INSTRUCTION

| Choice | Signal |
|---|---|
| Put it in `AGENT_INSTRUCTION` | The agent's core identity, always-on methodology, output contract. |
| Put it in a skill | Domain-specific procedure the agent only needs for a subset of tasks, OR methodology reusable across multiple agents, OR something already packaged as a SKILL.md upstream. |

Don't paste skill bodies into `AGENT_INSTRUCTION` — that breaks progressive disclosure and wastes context. Reference the skill by name in the system prompt and let the agent open it at runtime.

## Long-Running Projects (Multi-Session Work)

Any task too large for a single `--max-turns` budget spans multiple agent runs. The patterns below come from Anthropic's internal Claude Code work and OpenAI's Codex-driven codebase — both teams discovered the same failure modes when agents hit the context-window boundary, and the same remedies.

The harness gives you the primitives (`read_file`/`patch_file` for line-accurate edits, `spawn_agent` for subagent delegation, `save_learning` for notes, skills for reusable methodology). The multi-session *pattern* layers on top of these — it's a convention for how files in the workspace carry state across sessions.

### Why multi-session work fails

Two patterns dominate:

1. **"Try to one-shot a huge task"** — the agent starts implementing feature after feature, never completes or verifies any of them, runs out of context, and leaves the next session looking at half-finished work with no clear truth about what's done.
2. **"Declare victory early"** — a later session sees that progress has been made, infers "looks done," and stops. The agent has no structured way to know what *done* means for the project.

Both failures share a root cause: **no persistent, structured record of project state that survives the context boundary**.

### The four files every long project should have

Put these at the project root (or under `context/` if you're pairing with the knowledge system):

| File | Purpose | Format |
|---|---|---|
| `feature_list.json` | Ground truth for "is it done?" — one entry per user-visible feature with a `passes: boolean` flag the agent flips only after end-to-end verification | **JSON** (not Markdown — see below) |
| `progress.md` | Human-readable session log — what was worked on, what completed, what state was left | Markdown, append-only |
| `init.sh` | Idempotent environment-setup script — agents run this at session start instead of re-deriving how to boot the project | Shell |
| Git | Checkpointing + recovery — every session ends with a commit; a broken session reverts to last known-good | `git`, not invented |

#### Why JSON for the feature list, not Markdown

Empirically, models are **less likely to silently modify or "tidy up" JSON** than Markdown. JSON has rigid structure that resists casual rewriting; Markdown invites reformatting. You want the feature list treated as inviolable ground truth, so encode it in a format that behaviorally matches that intent.

Example entry:

```json
{
  "category": "functional",
  "description": "New chat button creates a fresh conversation",
  "steps": [
    "Navigate to main interface",
    "Click the 'New Chat' button",
    "Verify a new conversation appears in the sidebar",
    "Check the chat area shows the welcome state"
  ],
  "passes": false
}
```

The `steps` field doubles as the end-to-end test the agent runs before flipping `passes: true`. The agent cannot verify a feature by reading code alone — that's how the "declare victory early" failure mode happens. It must follow the steps in a real environment (browser, CLI, API call).

### The standard startup sequence

Every coding session should begin with the same ritual. Encode this in the agent's `AGENT_INSTRUCTION` or use it as the opening of a `defaultTask`:

```
On session start, ALWAYS run in order:
1. list_files at cwd — confirm workspace layout
2. read_file progress.md — understand recent work
3. read_file feature_list.json — read ground truth
4. run bash init.sh or equivalent — get the project into a working state
5. run the project's smoke test — verify the baseline is green
6. Pick the highest-priority {"passes": false} feature and work on that one only
```

Only after the baseline is green does the agent start a new feature. If the smoke test fails, the agent fixes the existing breakage first — otherwise you pile new work on a broken foundation and the underlying problem becomes harder to isolate.

### Clean-state requirement at session end

Before the context fills up, the agent must leave the workspace in a state the next session can safely build on. Explicit checklist for the end of every session:

1. Run the smoke test — confirm nothing you did broke the baseline
2. If a feature was completed and verified, flip its `passes: true` in `feature_list.json`
3. Append a 2-3 line session summary to `progress.md` (what you worked on, what completed, what state you left)
4. `git add` + `git commit -m "<descriptive message>"` — this is the checkpoint
5. If the session left work half-done and broken, `git reset --hard HEAD~1` to the last clean commit — better to leave a green baseline than a polluted working tree

The git commit is more than a checkpoint; it's the recovery mechanism. When a later change breaks something, reverting to the previous known-good commit is how the agent untangles itself without burning context on archaeology.

### Initializer / coder split via `spawn_agent`

Anthropic's two-agent architecture maps cleanly onto agent-builder: the first session (the initializer) does nothing but scaffold `feature_list.json`, `progress.md`, and `init.sh`. All subsequent sessions use a different prompt that assumes those files exist. `spawn_agent` is the harness-level mechanism for that split — your top-level agent invokes a fresh-context subagent for each feature, each with a 2–3 turn budget.

```
[top-level agent]
  ├── read progress.md, feature_list.json
  ├── pick next {"passes": false} feature
  ├── spawn_agent({ task: "Implement and verify feature X. Steps: [...]", max_turns: 5 })
  │     └── [subagent, fresh context]
  │           ├── read_file the relevant source files (use start_line for precision)
  │           ├── patch_file the edits
  │           ├── run the feature's steps
  │           └── finish_task with outcome
  ├── [main agent updates feature_list.json + progress.md + git commit]
  └── loop
```

This shape — **orchestrator stays thin, children do the heavy lifting** — is the same pattern that made Codex scale to a million lines with three engineers. The orchestrator's context stays focused on "what's the next feature"; each subagent's context stays focused on "implement this one thing."

### Testing reality, not code

Agents that verify features by reading code or running unit tests alone systematically miss bugs that only appear end-to-end. The Claude Code team observed this so consistently they wired Puppeteer in. For agent-builder, the equivalents are:

| Feature class | Verification tool |
|---|---|
| Files / scripts | `run_in_container` with the appropriate image — run the actual script, check exit code + output |
| HTTP APIs | `fetch_url` against a local server (added to the allowlist) |
| Web UIs | `@modelcontextprotocol/server-puppeteer` via MCP — drive the browser and observe |
| CLIs | `define_tool` that shells out with `execFileSync`, or `run_in_container` |

The principle: **the agent's work quality is bounded by the quality of its feedback loops**. If the agent can't observe what a user would observe, it optimizes for proxies (unit tests pass, server responds 200) that don't correlate with actual correctness.

### What to put where

| State | File | Why |
|---|---|---|
| "Is it done yet?" | `feature_list.json` | Explicit, unambiguous, survives context boundaries |
| "What happened last time?" | `progress.md` | Narrative continuity; cheap to scan at session start |
| "How do I start this project?" | `init.sh` | Removes per-session reinvention cost |
| "Why does this pattern exist?" | Skill under `./skills/` | Reusable methodology, progressive disclosure |
| "What did I learn doing this?" | `save_learning` → `context/learnings.md` | Operational wisdom, append-only |
| "Checkpoints + recovery" | Git | Built for exactly this |

## Knowledge Agent Pattern

### Overview

The compounding wiki is a zero-infrastructure knowledge management pattern. Raw sources go in, the LLM compiles them into structured wiki articles, outputs get filed back, and every interaction enriches the knowledge base. No database, no vector store — just `.md` files with YAML frontmatter and a JSON manifest.

The key insight is **index-first routing**: read `wiki/index.md` first to decide where to look, like a human scanning a table of contents. This avoids brute-force file scanning and scales as the wiki grows.

### Directory Convention

```
context/
├── raw/                 # Ingested sources (.md with YAML frontmatter)
│   └── .manifest.json   # Tracks ingest/compile state
├── wiki/                # LLM-compiled knowledge
│   ├── index.md         # Master routing index (1-line summaries)
│   ├── concepts/        # One article per concept
│   └── summaries/       # One summary per raw doc
└── learnings.md         # Operational memory (append-only)
```

All paths are relative to `--cwd`. The agent creates directories on first use.

### File Format Specs

**Raw document** (`context/raw/*.md`):
```yaml
---
title: The article title
source: user | https://example.com
ingested: 2026-04-04
tags: [tag1, tag2]
type: article | transcript | notes | reference
compiled: false
---

Content goes here...
```

**Wiki concept article** (`context/wiki/concepts/*.md`):
```yaml
---
title: Concept Name
created: 2026-04-04
updated: 2026-04-04
sources: [raw-doc-slug.md, another-slug.md]
related: [other-concept.md]
tags: [tag1, tag2]
---

Synthesized explanation of the concept...
```

**Wiki summary** (`context/wiki/summaries/*.md`):
```yaml
---
title: Summary of Source Title
source: raw-doc-slug.md
created: 2026-04-04
---

Condensed summary of the source document...
```

**Wiki index** (`context/wiki/index.md`):
```markdown
# Knowledge Index
> 12 concepts, 8 summaries — updated 2026-04-04

## Concepts
- [concept-name.md](concepts/concept-name.md) — One-line summary
- [another-concept.md](concepts/another-concept.md) — One-line summary

## Summaries
- [source-title.md](summaries/source-title.md) — One-line summary
```

**Manifest** (`context/raw/.manifest.json`):
```json
[
  { "file": "slug.md", "title": "Title", "source": "user", "ingested": "2026-04-04", "compiled": false }
]
```

**Learnings** (`context/learnings.md`):
```markdown
# Operational Learnings

## [discovery] — 2026-04-04

What was learned...

---
```

### The Compilation Loop

This is what the LLM does using the built-in tools. Encode this workflow in the agent's system prompt:

1. **Discover** — `read_manifest({"filter":"uncompiled"})` to find unprocessed sources
2. **Read** — `read_file` each uncompiled raw source
3. **Compile** — For each source:
   - Write a summary to `context/wiki/summaries/` using `write_file`
   - Extract key concepts, create or update articles in `context/wiki/concepts/` using `write_file`
   - Cross-reference: add `related` links between concept articles that share themes
4. **Index** — Read existing `context/wiki/index.md`, merge new entries, write back
5. **Mark** — `mark_compiled({"file":"slug.md"})` for each processed source
6. **Learn** — `save_learning` about discoveries, patterns, or corrections found

Steps 3–4 use existing `read_file`/`write_file`. The knowledge tools handle ingestion and state tracking; the LLM handles synthesis.

### Handling Large Files

Two built-in mechanisms prevent large markdown files from blowing context:

**Auto-split on ingest:** `ingest_source` automatically splits content larger than 8KB into multiple parts, breaking on heading boundaries. Each part gets its own manifest entry linked by a `group` field, so the compiler can process them incrementally.

**Section-level reading:** `read_section` navigates any `.md` file by heading structure:
- `read_section({"path":"context/raw/big-article.md"})` — returns table of contents with character counts per section
- `read_section({"path":"context/raw/big-article.md", "heading":"Key Findings"})` — returns just that section

This is the PageIndex principle at the file level: read the structure first (cheap), then pull specific content (targeted). Agents should prefer `read_section` over `read_file` for any file that might exceed 4KB.

### Index-First Routing

When answering questions from the knowledge base:

1. `read_file({"path":"context/wiki/index.md"})` — scan the table of contents
2. Identify relevant articles from the 1-line summaries
3. `read_file` only those specific articles
4. If no index match, fall back to `search_context({"query":"..."})` for full-text search
5. Synthesize an answer citing the source articles

This is the key scaling strategy. As the wiki grows from 10 to 100+ articles, the index keeps retrieval fast and token-efficient — the agent reads one file to decide which others to pull, not every file.

### Knowledge Agent Example

```javascript
const AGENT_INSTRUCTION = `
You are a senior knowledge engineer specializing in information synthesis and curation.

Your approach:
1. Check for uncompiled sources: read_manifest with filter "uncompiled"
2. For each uncompiled source, read it and compile:
   - Write a concise summary to context/wiki/summaries/
   - Extract key concepts and write/update articles in context/wiki/concepts/
   - Cross-reference related concepts in their frontmatter
3. Update context/wiki/index.md with new entries (read existing, merge, write back)
4. Mark each processed source as compiled
5. Save any discoveries or patterns to learnings
6. Call finish_task with a summary of what was compiled

When answering questions:
1. Read context/wiki/index.md first — scan for relevant articles
2. Read only the articles that match — do not scan every file
3. If the index has no match, use search_context as a fallback
4. Synthesize an answer from the retrieved articles, citing sources

Output format:
- Wiki articles as markdown with YAML frontmatter
- Save all artifacts under context/
- Call finish_task with a summary of what was compiled and learned

Focus on:
- Accurate synthesis — never fabricate facts not in the sources
- Cross-referencing — link related concepts to build a connected wiki
- Incremental growth — each run should leave the wiki richer than before
- Index maintenance — the index is the routing layer, keep it current
`;
```

## Testing

```bash
node agent.js "Your test task"                              # 1. Preview planned tool calls
node agent.js "Write a hello world file" --yolo             # 2. Simple task, verify execution
node agent.js "Research AI trends and create a report" --yolo  # 3. Complex workflow
```

Always test in preview mode first, then with `--yolo`.

## Model Selection

Browse all available models: https://ollama.com/library (or API: `https://ollama.com/api/tags`)

Before creating an agent, check what's installed and what the system can run:

```bash
ollama list                                        # installed models
system_profiler SPHardwareDataType | grep Memory   # macOS — check RAM
free -h                                            # Linux — check RAM
wmic OS get TotalVisibleMemorySize                 # Windows — check RAM
```

### Pick a model that fits the machine

Rule of thumb: model file size should be ≤ 75% of available RAM (the OS and Ollama need the rest).

| System RAM | Max model size | Good picks |
|---|---|---|
| 8GB | ~3-4GB (~4B params) | `gemma3:4b`, `phi4-mini`, `ministral-3:3b` |
| 16GB | ~6-10GB (~9B params) | `qwen3.5:9b`, `gemma3:12b`, `ministral-3:8b` |
| 32GB | ~14-20GB (~27B params) | `mistral-small`, `gemma3:27b`, `devstral-small-2:24b`, `deepseek-r1:14b` |
| 64GB+ | ~40-65GB (~70B+ params) | `qwen3-coder-next`, `deepseek-v3.1`, `mistral-large-3` |

### Match model to agent type

| Agent type | Recommended models | Why |
|---|---|---|
| **Code analysis / generation** | `qwen3-coder`, `devstral-small-2`, `gpt-oss`, `deepseek-r1` | Code-trained, follow structured tool-call patterns well |
| **Research / summarization** | `mistral-small`, `gemma3`, `qwen3.5` | Strong reasoning and synthesis |
| **Reasoning / multi-step** | `deepseek-r1`, `cogito`, `qwen3.5` | Chain-of-thought, planning |
| **Data / structured output** | `qwen3.5`, `mistral-small`, `nemotron-3-nano` | Reliable JSON/table output |
| **Vision / multimodal** | `gemma3` (with vision), `qwen3-vl` | Can process images |
| **General purpose** | `mistral-small` (default), `gemma3` | Balanced across tasks |

### Install a model

```bash
ollama pull mistral-small      # default — good all-rounder (14GB, needs 32GB RAM)
ollama pull qwen3.5:9b         # smaller — fits 16GB RAM
ollama pull gemma3:4b          # smallest — fits 8GB RAM
```

When recommending a model in the agent's docs, always state the model name, file size, and minimum RAM so users know if it'll run on their machine.

## Provider Quick Reference

| Prefix | Example | Key source |
|---|---|---|
| (none) | `--model mistral-small` | Ollama (default, free, local) |
| `ollama:` | `--model ollama:deepseek-r1` | Ollama |
| `openai:` | `--model openai:gpt-5-mini` | `OPENAI_API_KEY` / `--openai-key` |
| `anthropic:` | `--model anthropic:claude-sonnet-4-5` | `ANTHROPIC_API_KEY` / `--anthropic-key` |
| `gemini:` | `--model gemini:gemini-2.5-flash` | `GEMINI_API_KEY` / `--gemini-key` |

Model-name inference: `gpt-*` → OpenAI, `claude-*` → Anthropic, `gemini-*` → Google. Everything else → Ollama.

## Checklist

- [ ] Copied stub (never edited `agent.stub` directly)
- [ ] Scaffold fully filled — no `[BRACKETED]` placeholders remain
- [ ] `defaultTask` set in CONFIG so `node <name>.js --yolo` works without a task argument
- [ ] Expert persona is specific, not generic
- [ ] System prompt covers: boundaries, methodology, edge cases, self-verification, fallbacks, output contract
- [ ] Domain tools implemented with validation and error handling
- [ ] Tested in preview mode, then with `--yolo`
- [ ] Agent definition JSON produced (identifier + whenToUse + systemPrompt)
- [ ] *(Knowledge agents)* `context/` directory convention documented in system prompt
- [ ] *(Knowledge agents)* Compilation loop encoded in agent's approach steps

## Tool Discovery

Built-in tools are documented in the stub. From inside a running agent:
- `<<tool:help {}>>` — list all tools
- `<<tool:help {"tool":"write_file"}>>` — show one tool's signature and example
