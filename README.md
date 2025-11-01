# Agent Builder 💬

**Local-first agents, zero fluff.**

Chat. Build. Run.

## What is this?

A streamlined template (`agent.stub`) that AI coding assistants use to create working agents instantly.

**You describe what you want → AI transforms the stub → Working agent in seconds**

Think of it as a template that AI fills in to create:
- 🔧 Agents that use tools (files, web, APIs, anything)
- 🧠 Agents that think step-by-step to solve problems
- ⚡ Agents that create new tools on-the-fly when needed
- 🎯 Agents that complete complex multi-step tasks autonomously

**No frameworks. No npm dependencies. Just Node.js and AI.**

### Choose Your AI Assistant:
Various AI coding assistants can transform the agent stub into working agents.
These tools understand natural language and can build your agent — pick any one that works for you!

## Getting Started

### What You Need:
- A computer with internet
- Node.js ([Download here](https://nodejs.org) - installs like any app)
- Git (Windows: [Download here](https://git-scm.com); Mac/Linux: usually pre-installed)
- 5 minutes to set up

### Opening Terminal

Terminal is an app that lets you type commands.

**On Mac:**
1. Press `Command ⌘ + Space`
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

### Three Simple Steps:

#### 1. Get the Agent Builder

Run these commands one at a time in Terminal:

**First** - Copy the agent builder to your computer:
```bash
git clone https://github.com/builtbyV/agent-builder.git
```
Press Enter and wait until the download finishes.

💡 **Tip:** You'll know it's finished when you see your Terminal prompt ($ or similar) again.

**Then** - Go into your project folder:
```bash
cd agent-builder
```
Press Enter.

**💡 Troubleshooting:**
- If you see 'No such file or directory', the download probably isn't complete yet. Wait a bit and try again.
- You should see `agent-builder` in your Terminal prompt after this command

#### 2. Run Setup

In your Terminal window (make sure you're inside the `agent-builder` folder), run this command:
```bash
bash setup.sh
```

💡 **Don't worry if you see lots of text scrolling by—this is normal! Just wait until it stops and you see your Terminal prompt again.**

This command automatically does everything for you:
- ✅ Check your computer is ready
- ✅ Install and configure Ollama (local AI)
- ✅ Set everything up for you

#### 3. Start Building!

Start your preferred AI coding assistant. For example:
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

💡 **Remember:** If you make a mistake, just tell your AI assistant to fix it - nothing will break!

## 💻 Helpful Terminal Commands

Just a few commands you might need:

- `cd folder-name` - Go into a folder
- `cd ..` - Go back up one folder  
- `ls` - See what's in current folder (works in Git Bash on Windows too)
- `pwd` - See where you are

**Examples:**

Enter your project folder:
```bash
cd agent-builder
```

Go back to the previous folder:
```bash
cd ..
```

See what files are in current folder:
```bash
ls
```

Check which folder you're in:
```bash
pwd
```

### Stopping Running Processes:
- **Windows/Linux**: Press `Ctrl + C` to stop any running command
- **Mac**: Press `Command + C` to stop any running command
- This is useful when you need to stop running agents or Ollama

## Example Agent Creation Prompts

Tell your AI assistant what kind of agent you need:

### Research Agent
```
"Create a research agent that can search the web for information,
analyze sources, and compile findings into structured reports"
```

### Code Analysis Agent
```
"Build a code review agent that analyzes code for security vulnerabilities,
performance issues, and suggests improvements with detailed explanations"
```

### Data Processing Agent
```
"Make a data analyst agent that processes CSV files, identifies patterns
and trends, generates statistics, and creates visual reports"
```

### Content Creator Agent
```
"Create a content writer agent that researches topics, outlines articles,
writes engaging content, and formats it properly for publishing"
```

### File Organizer Agent
```
"Build an agent that organizes files by type, date, or content,
removes duplicates, and creates a clean folder structure"
```

### API Integration Agent
```
"Create an agent that can call multiple APIs, transform data between
formats, and handle authentication and error cases"
```

## The Magic: Dynamic Tool Creation

The agent can create any tool it needs on the fly:

```javascript
<<tool:define_tool {"name": "fetch_weather", "code": "const r = await fetch(`https://api.weather.com/${args.city}`); const data = await r.json(); return JSON.stringify(data, null, 2);"}>
```

No need to pre-define everything. The agent figures it out.

## Features

- **🚀 Zero npm dependencies** - Just Node.js and Ollama (no npm install needed)
- **🎯 Single File** - The entire agent in one file
- **🔧 Extensible** - Agent creates tools as needed
- **🛡️ Safe by Default** - Preview actions before execution (--yolo to auto-run)
- **🌐 Multiple Models** - Ollama (local) and various cloud providers
- **📁 File Operations** - Read, write, organize files
- **🌍 Web Access** - Fetch URLs, search, scrape (agent creates the tools)
- **⚡ Fast Iteration** - Test and modify in seconds

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

## Advanced Usage

After your AI assistant creates an agent, you can run it with various options and features:

<details>
<summary><b>📝 Command-Line Options</b></summary>

```bash
# Basic usage
node my-agent.js "Your task"

# Auto-execute tools without confirmation
node my-agent.js "Your task" --yolo

# Set working directory for file operations
node my-agent.js "Your task" --cwd ./workspace

# Override max iterations (default: 5)
node my-agent.js "Your task" --max-turns 10

# Default: Ollama with mistral-small (free, runs locally)
node my-agent.js "Your task"  # Uses ollama:mistral-small by default

# Other good Ollama models
node my-agent.js "Your task" --model mixtral
node my-agent.js "Your task" --model codellama
node my-agent.js "Your task" --model llama3.2
node my-agent.js "Your task" --model deepseek-r1

# General-purpose cloud alternatives (require API keys)
node my-agent.js "Your task" --model gpt-5-mini         # OpenAI
node my-agent.js "Your task" --model claude-sonnet-4-5  # Anthropic
node my-agent.js "Your task" --model gemini-2.5-flash   # Google

# Or use provider:model prefix format
node my-agent.js "Your task" --model openai:gpt-5
node my-agent.js "Your task" --model anthropic:claude-opus-4-1
node my-agent.js "Your task" --model ollama:mistral-small

# Specify provider explicitly
node my-agent.js "Your task" --provider openai
node my-agent.js "Your task" --provider anthropic
node my-agent.js "Your task" --provider gemini
node my-agent.js "Your task" --provider ollama

# Pass API keys directly (instead of using environment variables)
node my-agent.js "Your task" --openai-key sk-...
node my-agent.js "Your task" --anthropic-key sk-ant-...
node my-agent.js "Your task" --gemini-key AIza...

# Save API keys to .env file for future use
node my-agent.js "Your task" --save-keys
```
</details>

<details>
<summary><b>🔧 Built-in Tools</b></summary>

Every agent created from the stub includes these tools:

```
• list_files     - List files in workspace (path, pattern)
• read_file      - Read text files (path, max_bytes=200KB)
• write_file     - Write text files (path, content)
• delete_file    - Delete workspace files (path)
• fetch_url      - HTTP requests (url, method, headers, body, max_bytes=200KB)
• search_web     - DuckDuckGo search (query, max_results)
• scrape_page    - Extract text from web pages (url, max_bytes=200KB)
• download_file  - Download files to workspace (url, path)
• define_tool    - Create new tools at runtime (name, code)
• help           - Get tool documentation (tool)
```
</details>

<details>
<summary><b>⚡ Dynamic Tool Creation</b></summary>

Agents can create new tools on-the-fly:

```javascript
// The agent can define custom tools as needed:
<<tool:define_tool {
  "name": "analyze_json",
  "code": "const {data} = args; return JSON.stringify(JSON.parse(data), null, 2);"
}>>

// Dynamic tools have access to a file helper (workspace-confined):
<<tool:define_tool {
  "name": "count_files",
  "code": "const files = await file.list(args.path || '.'); return `Found ${files.length} items`;"
}>>
```

The file helper provides (automatically bound to workspace):
- `file.write(path, content)` - Write files
- `file.read(path, maxBytes)` - Read files
- `file.list(path)` - List directory contents
</details>

<details>
<summary><b>🔐 Environment Variables</b></summary>

```bash
# Ollama configuration
OLLAMA_HOST=http://localhost:11434  # Default Ollama server

# API Keys (loaded from .env file or environment)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=AIza...

# Custom API endpoints (for proxies or local deployments)
OPENAI_BASE_URL=https://api.openai.com
ANTHROPIC_BASE_URL=https://api.anthropic.com
ANTHROPIC_VERSION=2023-06-01

# Debugging
LOG_LEVEL=debug  # Options: debug, info, warn, error
```
</details>

<details>
<summary><b>🐛 Debugging</b></summary>

```bash
# Enable debug logging to see all model interactions
LOG_LEVEL=debug node my-agent.js "Your task"

# Preview what tools will be called without executing
node my-agent.js "Your task"  # No --yolo flag

# See the help for any tool (agent will call it)
node my-agent.js "Show me the help for the fetch_url tool" --yolo
```
</details>

<details>
<summary><b>🛡️ Safety Features</b></summary>

The agent stub includes built-in safety measures:

```
• Path Protection    - Files can only be accessed within the working directory
• Output Truncation  - Large outputs are automatically truncated (4KB default)
• Tool Timeouts      - Tools timeout after 30 seconds to prevent hanging
• File Size Limits   - read_file defaults to 200KB max to prevent memory issues
• Preview Mode       - Without --yolo, shows what would be executed
• Sandbox for Dynamic Tools - Limited environment for runtime-created tools
• Smart JSON Parser  - Handles common LLM mistakes (trailing commas, quotes, etc.)
```
</details>

## Requirements

- Node.js 18+
- Ollama (free local AI)

### Setting up Ollama

```bash
# 1. Install from https://ollama.ai

# 2. Pull a model:
ollama pull mistral-small

# 3. Start Ollama:
ollama serve
```

That's it! Now you can run agents locally for free.

## Philosophy

> "Make it as simple as possible, but not simpler." - Einstein (probably)

- **One file** that does real work
- **No frameworks** to learn
- **No npm dependencies** to manage
- **No complexity** to debug
- **Just results**

## Use Cases

- 📊 **Data Analysis** - Process CSVs, generate reports
- 🔍 **Research** - Gather information, summarize findings
- 📝 **Content Creation** - Write articles, documentation
- 🛠️ **Code Generation** - Create boilerplate, tests
- 🧹 **Automation** - Organize files, process batches
- 🔄 **Integration** - Connect APIs, transform data
- 📧 **Communication** - Draft emails, create presentations

## Contributing

Have ideas? Found bugs? Want to add features?

1. Fork it
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

Keep it simple. That's the only rule.

## ❓ Common Questions

**Q: Do I need to know how to code?**  
A: Not at all! Just describe what you want in your own words.

**Q: What if I make a mistake?**  
A: Just tell your AI to undo it or change it back. Everything is saved, so you can't break anything.

**Q: How much does this cost?**  
A: The template is free! Ollama runs locally for free. Your AI assistant (Claude Code, Codex, etc.) may have its own pricing.

**Q: Can it do X?**  
A: If you can describe it, your AI can build an agent for it. The agent creates the tools it needs.

**Q: Why --yolo?**  
A: Because "You Only Live Once" perfectly captures the spirit of running code without confirmation. Plus it's fun to type.

## 🛠️ Optional: Easy Text Editors

While your AI assistant handles most changes, you might want to make quick edits yourself. Here are free, beginner-friendly editors:

### Visual Studio Code (Recommended)
- **Download**: [code.visualstudio.com](https://code.visualstudio.com)
- **Why**: Most popular, free, works on all computers
- **Tip**: It highlights code in colors making it easier to read

### Simple Alternatives:
- **Sublime Text**: [sublimetext.com](https://www.sublimetext.com) - Clean, fast, and simple
- **Mac**: TextEdit (already installed) - Just switch to "Plain Text" mode
- **Windows**: Notepad (already installed) - Simple and basic
- **Linux**: Usually comes with gedit or similar
- **Online**: [vscode.dev](https://vscode.dev) - Works in your browser, no installation needed!

💡 **You don't need to use any editors if you don't want to!** Your AI assistant can handle everything. Editors are just there if you prefer making quick edits yourself.

## 📚 Learn More

These guides will help you get the most out of your AI coding assistant for building agents:

- **Claude Code Guide**: [Getting Started with Claude Code](https://docs.anthropic.com/en/docs/claude-code/quickstart) - Learn about Claude's coding capabilities, command options, and best practices for agent creation
- **OpenAI Codex Guide**: [Getting Started with Codex CLI](https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started) - Understand Codex's features, API integration, and how to optimize agent development
- **Gemini CLI Guide**: [Getting Started with Gemini CLI](https://github.com/google-gemini/gemini-cli) - Explore Gemini's free tier, model selection, and agent building techniques

Each assistant has its own strengths - explore their docs to find advanced features and tips for creating more powerful agents.

## Troubleshooting

**"Ollama error"**
- Make sure Ollama is running: `ollama serve`
- Check it's accessible: `curl http://localhost:11434`

**"Tool execution failed"**
- Run without --yolo first to see what it's trying to do
- Check file permissions if working with files

## License

MIT - Do whatever you want with it.

---

**Remember**: The best code is code you don't have to write. Let the agent write it for you.

```bash
# Tell your AI assistant:
"Create an agent that helps me build something amazing"

# Then run your new agent:
node amazing-builder.js "Design a web application architecture" --yolo
```

---

Assembled by [V](https://v.ee) to make agent development accessible to everyone.