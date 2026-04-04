# Agent Builder

**A local-first agent harness. Zero dependencies, one file, real work.**

Chat. Build. Run.

## What is this?

An agent harness (`agent.stub`) — a complete runtime that AI coding assistants transform into working agents. It handles the execution loop: tool dispatch, turn management, context compression, subagent spawning, and safety gates. You describe what you want, AI fills in the persona and tools, and the harness runs it.

**You describe what you want → AI customizes the harness → Working agent in seconds**

The harness creates:
- **Tool-using agents** — files, web, APIs, anything
- **Reasoning agents** — step-by-step problem solving with subagent decomposition
- **Self-extending agents** — create new tools on-the-fly at runtime
- **Knowledge agents** — build a compounding wiki from raw sources that grows richer over time

**No frameworks. No npm dependencies. Just Node.js and AI.**

### Choose Your AI Assistant
Various AI coding assistants can transform the agent harness into working agents.
These tools understand natural language and can build your agent — pick any one that works for you!

## Getting Started

### What You Need
- A computer with internet
- Node.js ([Download here](https://nodejs.org) — installs like any app)
- Git (Windows: [Download here](https://git-scm.com); Mac/Linux: usually pre-installed)
- 5 minutes to set up

### Opening Terminal

Terminal is an app that lets you type commands.

**On Mac:**
1. Press `Command + Space`
2. Type **Terminal**
3. Press **Enter**

**On Windows:**
1. Install Git for Windows from [git-scm.com](https://git-scm.com/download/win) if you haven't already
2. Right-click on your desktop or in a folder
3. Select **"Git Bash Here"**

**On Linux:**
1. Press `Ctrl + Alt + T`
Or search for "Terminal" in your applications

You'll see a window with text and a blinking cursor — this is where you'll type commands!

### Three Simple Steps

#### 1. Get the Agent Builder

Run these commands one at a time in Terminal:

**First** — Copy the agent builder to your computer:
```bash
git clone https://github.com/builtbyV/agent-builder.git
```
Press Enter and wait until the download finishes.

**Then** — Go into your project folder:
```bash
cd agent-builder
```

**Troubleshooting:**
- If you see 'No such file or directory', the download probably isn't complete yet. Wait and try again.
- You should see `agent-builder` in your Terminal prompt after this command

#### 2. Run Setup

In your Terminal window (make sure you're inside the `agent-builder` folder):
```bash
bash setup.sh
```

Don't worry if you see lots of text scrolling by — this is normal! Just wait until it stops and you see your Terminal prompt again.

This command automatically does everything for you:
- Check your computer is ready
- Install and configure Ollama (local AI)
- Set everything up for you

#### 3. Start Building!

Start your preferred AI coding assistant:
```bash
# Examples of starting different AI assistants:
npx claude    # or
npx codex     # or
npx gemini    # or your preferred tool
```

**What this does:** Starts an AI assistant so you can chat directly in the Terminal.

That's it! Now just tell your AI assistant what you want:
- "I need an agent that researches tech news"
- "Create an agent that can analyze code for security issues"
- "Build an agent that processes CSV files and creates reports"
- "Make a knowledge agent that compiles articles into a wiki"

If you make a mistake, just tell your AI assistant to fix it — nothing will break!

<details>
<summary><b>Helpful Terminal Commands</b></summary>

Just a few commands you might need:

- `cd folder-name` — Go into a folder
- `cd ..` — Go back up one folder
- `ls` — See what's in current folder (works in Git Bash on Windows too)
- `pwd` — See where you are

**Examples:**
```bash
cd agent-builder   # Enter your project folder
cd ..              # Go back to the previous folder
ls                 # See what files are in current folder
pwd                # Check which folder you're in
```

**Stopping Running Processes:**
- **Windows/Linux**: Press `Ctrl + C` to stop any running command
- **Mac**: Press `Command + C` to stop any running command
- This is useful when you need to stop running agents or Ollama
</details>

## Features

**The harness handles:**
- **Turn management** — turn-aware prompting, context compression, automatic message summarization
- **Subagent spawning** — decompose big tasks into focused subtasks with fresh contexts via `spawn_agent`
- **Parallel tool execution** — independent tool calls run concurrently
- **Error recovery** — actionable hints on failures (not raw stack traces)
- **Safe by default** — preview tool calls before execution (`--yolo` to auto-run)

**What you get:**
- **Zero npm dependencies** — Just Node.js and Ollama
- **Single file** — The entire agent in one `.js` file
- **18 built-in tools** — Files, web, search, knowledge base, orchestration
- **Dynamic tools** — Agent creates tools at runtime as needed
- **Knowledge system** — Ingest sources, compile a wiki, search with `rg`/`grep`, learnings that compound
- **Multiple providers** — Ollama (local, free), OpenAI, Anthropic, Google

## Example Agents

Tell your AI assistant what kind of agent you need:

```
"Create a research agent that searches the web, cross-references sources,
and compiles findings into structured reports"
```

```
"Build a code review agent that analyzes code for security vulnerabilities,
performance issues, and suggests improvements"
```

```
"Make a knowledge agent that ingests articles and papers, compiles them
into a wiki of concept articles, and answers questions from the wiki"
```

```
"Create a data analyst agent that processes CSV files, identifies patterns,
and generates statistics"
```

## Safety First

By default, the agent shows you what it plans to do:

```bash
$ node agent.js "Delete old logs"

=== Tool Calls Detected ===
- list_files: {"path": "logs", "pattern": "*.old"}
- delete_file: {"path": "logs/2023-01.old"}
- delete_file: {"path": "logs/2023-02.old"}

Run with --yolo to execute automatically
```

Review first, then run with `--yolo` if you approve.

## Built-in Tools

Every agent created from the stub includes:

```
File Tools         Knowledge Tools         Web Tools
─────────────      ──────────────────      ─────────────
list_files         ingest_source           fetch_url
read_file          read_manifest           search_web
write_file         mark_compiled           scrape_page
delete_file        search_context          download_file
read_section       save_learning

Orchestration      Meta Tools
──────────────     ──────────
spawn_agent        define_tool
finish_task        help
```

The knowledge tools enable a **compounding wiki pattern**: ingest raw sources → compile into structured articles → maintain an index → every interaction enriches the knowledge base. See `AGENTS.md` for the full Knowledge Agent Pattern.

## Claude Code with Ollama (Fully Offline)

You can run Claude Code — the AI assistant that builds your agents — entirely offline using Ollama's Anthropic-compatible API. This means both the **agent builder** (Claude Code) and the **agents it creates** run locally.

```bash
# Quick setup — launches Claude Code with a local model
ollama launch claude

# Or with a specific model
ollama launch claude --model qwen3.5
```

<details>
<summary><b>Manual setup</b></summary>

```bash
# Set environment variables
export ANTHROPIC_AUTH_TOKEN=ollama
export ANTHROPIC_API_KEY=""
export ANTHROPIC_BASE_URL=http://localhost:11434

# Run Claude Code with an Ollama model
claude --model qwen3.5
```
</details>

**Recommended models for Claude Code + Ollama:**

| System RAM | Models |
|---|---|
| 16GB | `qwen3.5`, `glm-4.7-flash` |
| 32GB | `qwen3.5:cloud`, `glm-5:cloud`, `kimi-k2.5:cloud` |
| 64GB+ | `minimax-m2.7`, `qwen3-coder-next`, `gemma4` |

Cloud models are also available at [ollama.com/search?c=cloud](https://ollama.com/search?c=cloud). See the [Ollama docs](https://docs.ollama.com) for the full documentation index.

> **Note:** Claude Code requires a large context window. We recommend at least 64k tokens. See the [context length documentation](https://docs.ollama.com/context-length) for how to adjust context length in Ollama.

## Advanced Usage

<details>
<summary><b>Command-Line Options</b></summary>

```bash
# Basic usage
node my-agent.js "Your task"                                # Preview tool calls
node my-agent.js "Your task" --yolo                         # Auto-execute tools
node my-agent.js --yolo                                     # Run default task

# Working directory and turns
node my-agent.js "Your task" --cwd ./workspace              # Confine file ops
node my-agent.js "Your task" --max-turns 10                 # Override 5-turn default

# Ollama models (local, free)
node my-agent.js "Your task" --model mistral-small          # Default
node my-agent.js "Your task" --model qwen3-coder-next       # Code-focused
node my-agent.js "Your task" --model deepseek-r1            # Reasoning
node my-agent.js "Your task" --model gemma4                 # General + vision

# Cloud providers (require API keys)
node my-agent.js "Your task" --model gpt-5-mini             # OpenAI
node my-agent.js "Your task" --model claude-sonnet-4-5      # Anthropic
node my-agent.js "Your task" --model gemini-2.5-flash       # Google

# Provider prefix format
node my-agent.js "Your task" --model openai:gpt-5
node my-agent.js "Your task" --model anthropic:claude-opus-4-1
node my-agent.js "Your task" --model ollama:mistral-small

# API keys
node my-agent.js "Your task" --openai-key sk-...
node my-agent.js "Your task" --anthropic-key sk-ant-...
node my-agent.js "Your task" --gemini-key AIza...
node my-agent.js "Your task" --save-keys                    # Persist to .env
```
</details>

<details>
<summary><b>Dynamic Tool Creation</b></summary>

Agents can create new tools on-the-fly:

```javascript
<<tool:define_tool {
  "name": "analyze_json",
  "code": "const {data} = args; return JSON.stringify(JSON.parse(data), null, 2);"
}>>

// Dynamic tools have access to a workspace-confined file helper:
<<tool:define_tool {
  "name": "count_files",
  "code": "const files = await file.list(args.path || '.'); return `Found ${files.length} items`;"
}>>
```

Dynamic tools run in a sandbox with access to: `fetch`, `file.read/write/list`, `args`, `AppError`, `assertString`, `truncate`.
</details>

<details>
<summary><b>Environment Variables</b></summary>

```bash
OLLAMA_HOST=http://localhost:11434  # Ollama server (default)
OPENAI_API_KEY=sk-...              # OpenAI
ANTHROPIC_API_KEY=sk-ant-...       # Anthropic
GEMINI_API_KEY=AIza...             # Google
OPENAI_BASE_URL=https://...        # Custom API endpoints
ANTHROPIC_BASE_URL=https://...
LOG_LEVEL=debug                    # debug, info, warn, error
```
</details>

<details>
<summary><b>Safety Features</b></summary>

```
Path Protection       Files confined to working directory (safePath)
Output Truncation     Large outputs capped at 4KB (configurable)
Tool Timeouts         30-second timeout per tool call
Preview Mode          Without --yolo, shows planned actions only
Dynamic Tool Sandbox  Runtime tools get limited environment
Smart JSON Parser     Handles LLM mistakes (trailing commas, quotes)
System Search         search_context uses rg/grep when available
Auto-Split            Large ingested files split on heading boundaries
```
</details>

## Model Selection

Before creating an agent, check what your system can run:

```bash
ollama list                                         # Installed models
system_profiler SPHardwareDataType | grep Memory    # macOS RAM
```

| System RAM | Max model size | Good picks |
|---|---|---|
| 8GB | ~3-4GB | `gemma3:4b`, `phi4-mini` |
| 16GB | ~6-10GB | `qwen3.5:9b`, `gemma3:12b` |
| 32GB | ~14-20GB | `mistral-small`, `gemma3:27b`, `deepseek-r1:14b` |
| 64GB+ | ~40-65GB | `qwen3-coder-next`, `minimax-m2.7`, `gemma4` |

| Agent type | Recommended models |
|---|---|
| **Code** | `qwen3-coder-next`, `devstral-small-2`, `deepseek-r1` |
| **Research** | `mistral-small`, `gemma3`, `qwen3.5` |
| **Knowledge** | `qwen3.5`, `mistral-small`, `gemma4` |
| **Reasoning** | `deepseek-r1`, `qwen3.5` |
| **General** | `mistral-small`, `gemma3` |

## Philosophy

> "Make it as simple as possible, but not simpler."

- **One file** that does real work
- **No frameworks** to learn
- **No npm dependencies** to manage
- **No complexity** to debug
- **Just results**

## Common Questions

**Q: Do I need to know how to code?**
A: No. Describe what you want in your own words.

**Q: How much does this cost?**
A: The template is free. Ollama runs locally for free. Your AI assistant may have its own pricing.

**Q: Can it do X?**
A: If you can describe it, your AI can build an agent for it.

**Q: Why --yolo?**
A: "You Only Live Once" — perfectly captures running code without confirmation. Plus it's fun to type.

## Troubleshooting

**"Ollama error"** — Make sure Ollama is running: `ollama serve` / check: `curl http://localhost:11434`

**"Tool execution failed"** — Run without `--yolo` first to see what it's trying to do.

**Large files truncated** — Use `read_section` to navigate by heading, or pass `max_bytes` to `read_file`.

## Learn More

- **Claude Code**: [Getting Started](https://docs.anthropic.com/en/docs/claude-code/quickstart) — also works [offline with Ollama](https://docs.ollama.com)
- **OpenAI Codex**: [Getting Started](https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started)
- **Gemini CLI**: [Getting Started](https://github.com/google-gemini/gemini-cli) — free tier available
- **Ollama**: [Documentation Index](https://docs.ollama.com/llms.txt) — all available models and docs

## Contributing

1. Fork it
2. Create your feature branch
3. Commit your changes
4. Open a Pull Request

Keep it simple. That's the only rule.

## License

MIT — Do whatever you want with it.

---

**Remember**: The best code is code you don't have to write. Let the agent write it for you.

```bash
"Create an agent that helps me build something amazing"
node amazing-builder.js "Let's go" --yolo
```

---

Assembled by [V](https://v.ee) to make agent development accessible to everyone.
