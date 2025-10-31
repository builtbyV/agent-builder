# Agent Builder 💬 

**Local-first agents, zero fluff.**

Chat. Build. Run.

```bash
node agent.js "Create a research agent and analyze the latest AI trends" --yolo
```

## What is this?

A streamlined stub that AI coding assistants use to create working agents instantly.

**You describe what you want → AI transforms the stub → Working agent in seconds**

Think of it as a template that AI fills in to create:
- 🔧 Agents that use tools (files, web, APIs, anything)
- 🧠 Agents that think step-by-step to solve problems
- ⚡ Agents that create new tools on-the-fly when needed
- 🎯 Agents that complete complex multi-step tasks autonomously

**No frameworks. No dependencies. Just Node.js and AI.**

### Choose Your AI Assistant:
- **Claude Code** - AI coding agent by Anthropic
- **OpenAI Codex CLI** - AI coding agent by OpenAI  
- **Google Gemini CLI** - AI coding agent by Google (FREE tier available!)

All these coding tools understand natural language and can build your agent — pick any one!

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

Choose your AI assistant and tell it to create an agent:

**For Claude Code:**
```bash
npx claude
```

**For OpenAI Codex:**
```bash
npx codex
```

**For Gemini CLI:**
```bash
npx gemini
```

**What this does:** Starts your AI assistant so you can chat directly in the Terminal.

That's it! Now just tell your AI assistant what you want:
- "Hi Claude, I need an agent that researches tech news"
- "Create an agent that can analyze code for security issues"
- "Build an agent that processes CSV files and creates reports"

Give your AI the `agent.js` file and describe what kind of agent you need!

💡 **Remember:** If you make a mistake, just tell your AI assistant to fix it - nothing will break!

## How It Works

1. **Give the stub to your AI assistant** (Claude Code, Codex, Cursor, etc.)
2. **Describe the agent you want** in plain English
3. **AI transforms the stub** into a working agent
4. **Run it immediately** to complete your task

It's like the AI Website Builder, but for creating agents instead of websites!

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

## Examples

### Research Agent
```bash
node agent.js "Create a research agent and find the top 5 AI breakthroughs this week" --yolo
```

### Code Analysis Agent
```bash
node agent.js "Create a code review agent and analyze this project for security issues" --yolo --cwd ./my-project
```

### Data Processing Agent
```bash
node agent.js "Create a data analyst agent and analyze sales.csv for trends" --yolo
```

### Content Creator Agent
```bash
node agent.js "Create a blog writer agent and write an article about quantum computing" --yolo
```

## The Magic: Dynamic Tool Creation

The agent can create any tool it needs on the fly:

```javascript
<<tool:define_tool {"name": "fetch_weather", "code": "const r = await fetch(`https://api.weather.com/${args.city}`); return await r.json();"}>
```

No need to pre-define everything. The agent figures it out.

## Features

- **🚀 Zero Setup** - Just Node.js, nothing else
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

### Choose Your AI Model
```bash
# Local with Ollama (default, free)
node agent.js "Your task"

# Use a specific Ollama model
node agent.js "Your task" --model mixtral
node agent.js "Your task" --model codellama
node agent.js "Your task" --model llama3.2
```

### Set Working Directory
```bash
# Work with files in a specific directory
node agent.js "Organize these files by type" --cwd ./my-documents --yolo
```

### Create Custom Agents

1. Give the stub to your AI coding assistant (Claude Code, Codex, Cursor):
```bash
# Copy the stub content or share the file with your AI
```

2. Tell your AI what kind of agent you want:
```
"Using this agent.js file, create a research agent that can search the web and write reports"
```

3. AI creates your custom agent → Save it → Run it:
```bash
node my-research-agent.js "Research quantum computing breakthroughs" --yolo
```

## Requirements

- Node.js 18+ 
- Ollama (free local AI)

### Setting up Ollama

```bash
# 1. Install from https://ollama.ai

# 2. Pull a model:
ollama pull llama3.2

# 3. Start Ollama:
ollama serve
```

That's it! Now you can run agents locally for free.

## Philosophy

> "Make it as simple as possible, but not simpler." - Einstein (probably)

- **One file** that does real work
- **No frameworks** to learn
- **No dependencies** to manage  
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

- **Claude Code Guide**: [Getting Started with Claude Code](https://docs.anthropic.com/en/docs/claude-code/quickstart)
- **OpenAI Codex Guide**: [Getting Started with Codex CLI](https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started)
- **Gemini CLI Guide**: [Getting Started with Gemini CLI](https://github.com/google-gemini/gemini-cli)

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
# Your next command:
node agent.js "Help me build something amazing" --yolo
```

---

Assembled by [V](https://v.ee) to make agent development accessible to everyone.