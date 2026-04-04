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
