# AI Agent Creation Guide

## Quick Start

When a user asks you to create an agent, follow these steps:
1. Copy `agent.stub` to `agent.js` (or another name like `my-agent.js`)
2. Use this new file as your foundation
3. Transform it into a working agent based on user requirements

## Understanding the Request

First, identify what kind of agent the user wants:

1. **Purpose** - What is the agent's main job?
   - Research and information gathering
   - Code generation or analysis
   - Content creation (articles, reports, documentation)
   - Data analysis and visualization
   - Task automation
   - Domain-specific expertise (legal, medical, scientific)

2. **Capabilities** - What tools will it need?
   - File operations (read, write, organize)
   - Web access (fetch URLs, search, scrape)
   - Code execution or analysis
   - API integrations
   - Data processing
   - Communication (email, notifications)

3. **Output** - What should it produce?
   - Files (reports, code, data)
   - Direct answers
   - Step-by-step analysis
   - Structured data

## Step-by-Step Agent Creation

### Step 1: Copy the Stub

First, duplicate `agent.stub` to create your working file:
```bash
cp agent.stub agent.js  # Or use a descriptive name like research-agent.js
```

Now work with this new file. It provides:
- Tool calling infrastructure
- Provider support (Ollama by default; OpenAI, Anthropic, Gemini via flags or model prefix)
- Safety features (--yolo flag)
- Error handling
- CLI interface
- Universal scaffold + universal tool rules
- Tool discovery helper (`help`)

### Provider Selection Policy
- Default: Ollama (local‑first, free, zero keys)
- Explicit override: `--provider` or model prefixes `openai:`, `anthropic:`, `gemini:`, `ollama:`
- Model-only inference: If model clearly implies a vendor (`gpt-[345]`, `claude-*`, `gemini-*`), route there; otherwise stick to Ollama
- API keys: CLI flags > env vars (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`) > `.env` in CWD
- Interactive only: If still missing in an interactive TTY, prompts for the key (hidden). Optional `--save-keys` appends to local `.env`

### CLI Flags & Env
- `--provider|-p openai|anthropic|gemini|ollama`
- `--model|-m <model>` (prefix form also supported, e.g., `openai:gpt-5-mini`)
- `--max-turns <number>` (override default 5 turns)
- `--openai-key`, `--anthropic-key`, `--gemini-key` (override env)
- `--save-keys` (write prompted key to `.env` in the working directory)
- Env vars: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `OLLAMA_HOST`

### Universal Scaffold (Built‑in, fill this before tools)
The runner ships a single scaffold for any agent type. Replace all `[BRACKETED]` fields before calling tools. If something is ambiguous, choose sensible defaults and state them briefly—don’t ask for clarification.

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

### First‑Turn Protocol (MUST DO)
1. Agent Setup — Rewrite the scaffold with concrete values.
2. Plan — A short bullet list of actions and which tools you’ll call.
3. Execute — Call tools using strict JSON.
4. Deliver — Save artifacts to the declared paths and summarize results (show paths).

Tip: Tool discovery:
- `<<tool:help {}>>` lists tools
- `<<tool:help {"tool":"write_file"}>>` shows a tool’s signature and example payload

### Step 2: Implement Core Tools

Replace the `example_tool` with actual implementations. Follow this pattern:

```javascript
async tool_name(args, ctx) {
  // 1. Extract parameters
  const { param1, param2 = 'default' } = args || {};
  
  // 2. Validate required parameters
  assertString(param1, 'param1');
  
  // 3. Implement logic
  try {
    // Your implementation here
    const result = await doWork(param1, param2);
    
    // 4. Return concise result (auto-truncated)
    return truncate(result);
  } catch (error) {
    // 5. Handle errors gracefully
    throw new AppError(`Tool failed: ${error.message}`);
  }
}
```

### Step 3: Customize Agent Instructions

Modify the `AGENT_INSTRUCTION` (now a universal scaffold) to define:

1. **Role and Identity**
   ```javascript
   You are a [specific type] agent specialized in [domain].
   Your expertise includes [key areas].
   ```

2. **Approach and Methodology** (fill bracketed placeholders first)
   ```javascript
   Approach tasks by:
   1. [First step in your methodology]
   2. [Second step]
   3. [Continue with specific steps]
   ```

3. **Tool Usage Guidelines**
   ```javascript
   Use tools in this order:
   - Use [tool_name] to [purpose]
   - Use [tool_name] when [condition]
   - Chain [tool1] -> [tool2] for [complex task]
   ```

4. **Output Formatting**

Universal rules included in the stub:
- Use exact tool syntax: `<<tool:tool_name {"parameter":"value"}>>`
- Fill all `[BRACKETED]` placeholders in the scaffold before calling any tools
- Use strict JSON in tool calls (quoted keys, no trailing commas)
- Make multiple focused calls instead of one huge one
- If a step fails, try an alternative and explain what changed
   ```javascript
   Format your responses as:
   - [Specific format requirements]
   - Save artifacts as [file types]
   - Include [required sections]
   ```

### Step 4: Add Domain-Specific Tools

Based on the agent type, implement appropriate tools:

#### For Research Agents
```javascript
async web_search(args, ctx) {
  const { query, max_results = 5 } = args || {};
  // Implementation
}

async summarize_article(args, ctx) {
  const { url, max_words = 200 } = args || {};
  // Implementation
}

async compile_report(args, ctx) {
  const { topic, sources, format = 'markdown' } = args || {};
  // Implementation
}
```

#### For Coding Agents
```javascript
async analyze_code(args, ctx) {
  const { path, language } = args || {};
  // Implementation
}

async generate_tests(args, ctx) {
  const { code, framework = 'jest' } = args || {};
  // Implementation
}

async refactor_code(args, ctx) {
  const { path, patterns } = args || {};
  // Implementation
}
```

#### For Data Analysis Agents
```javascript
async load_data(args, ctx) {
  const { path, format = 'csv' } = args || {};
  // Implementation
}

async analyze_trends(args, ctx) {
  const { data, metrics } = args || {};
  // Implementation
}

async generate_visualization(args, ctx) {
  const { data, chart_type, output_path } = args || {};
  // Implementation
}
```

## Common Patterns

### 1. File-Based Workflow
```javascript
// Read -> Process -> Write pattern
async process_files(args, ctx) {
  const { input_dir, output_dir, operation } = args || {};
  
  // List files
  const files = fs.readdirSync(safePath(ctx.cwd, input_dir));
  
  // Process each file
  for (const file of files) {
    const content = fs.readFileSync(safePath(ctx.cwd, `${input_dir}/${file}`), 'utf8');
    const processed = await performOperation(content, operation);
    fs.writeFileSync(safePath(ctx.cwd, `${output_dir}/${file}`), processed);
  }
  
  return `Processed ${files.length} files`;
}
```

### 2. Web Research Pattern
```javascript
// Search -> Fetch -> Extract -> Synthesize
async research_topic(args, ctx) {
  const { topic, depth = 'medium' } = args || {};
  
  // First, search for sources
  const searchResults = await searchWeb(topic);
  
  // Fetch content from top sources
  const contents = [];
  for (const url of searchResults.slice(0, 5)) {
    const content = await fetchUrl(url);
    contents.push(extractKeyInfo(content));
  }
  
  // Synthesize findings
  const synthesis = synthesizeFindings(contents);
  
  // Save report
  fs.writeFileSync(
    safePath(ctx.cwd, `${topic.replace(/\s+/g, '_')}_report.md`),
    synthesis
  );
  
  return `Research complete. Report saved with ${contents.length} sources analyzed.`;
}
```

### 3. Multi-Step Processing
```javascript
// Complex workflows with intermediate steps
async complex_workflow(args, ctx) {
  const { input, stages = ['analyze', 'transform', 'validate'] } = args || {};
  
  let result = input;
  const stageResults = [];
  
  for (const stage of stages) {
    if (ctx.signal?.aborted) break;
    
    result = await processStage(stage, result);
    stageResults.push({ stage, summary: summarize(result) });
  }
  
  return `Workflow complete:\n${stageResults.map(s => `- ${s.stage}: ${s.summary}`).join('\n')}`;
}
```

## Dynamic Tool Creation

If the agent needs a tool that doesn't exist, it can create one on the fly:

```javascript
// Example: Agent creates a custom API integration
<<tool:define_tool {"name": "call_api", "code": "const response = await fetch(args.endpoint, { method: args.method || 'GET', headers: args.headers || {}, body: args.body ? JSON.stringify(args.body) : undefined }); return `Status: ${response.status}\\n${await response.text()}`;"}>
```

## Testing Your Agent

1. **Test without execution first**
   ```bash
   node agent.js "Your test task"
   ```
   Review the planned tool calls.

2. **Test with simple tasks**
   ```bash
   node agent.js "Write a hello world file" --yolo
   ```

3. **Test complex workflows**
   ```bash
   node agent.js "Research AI trends and create a report" --yolo
   ```

## Best Practices

### Tool Design
- **Single Responsibility**: Each tool should do one thing well
- **Descriptive Names**: Use `verb_noun` format (e.g., `fetch_data`, `analyze_code`)
- **Validate Inputs**: Always validate required parameters
- **Handle Errors**: Provide helpful error messages
- **Return Useful Output**: Include relevant details for the agent to continue

### Agent Instructions
- **Be Specific**: Clear, step-by-step instructions
- **Include Examples**: Show how tools should be used
- **Define Success**: What constitutes a complete task
- **Handle Edge Cases**: What to do when things go wrong

### Performance
- **Truncate Outputs**: Large outputs are automatically truncated to 4KB
- **Batch Operations**: Process multiple items in single tool calls when possible
- **Check Cancellation**: Respect `ctx.signal.aborted` in long operations
- **Cache When Possible**: Avoid redundant operations

## Examples by Agent Type

### Research Agent
```javascript
const AGENT_INSTRUCTION = `
You are an expert research analyst specializing in technology trends.

Your approach:
1. Search for recent, authoritative sources
2. Verify information across multiple sources
3. Synthesize findings into actionable insights
4. Create well-structured reports with citations

When researching:
- Prioritize recent sources (last 6 months)
- Cross-reference at least 3 sources per claim
- Save your report as markdown with proper formatting
- Include an executive summary

Available tools: ${Object.keys(ToolRegistry).join(', ')}
`;
```

### Code Assistant Agent
```javascript
const AGENT_INSTRUCTION = `
You are a senior software engineer specializing in code quality and architecture.

Your expertise:
- Code review and refactoring
- Test generation and coverage
- Performance optimization
- Security analysis

When working with code:
1. First analyze the existing structure
2. Identify patterns and anti-patterns
3. Suggest improvements with explanations
4. Generate tests for critical paths
5. Document your changes

Always consider: readability, maintainability, performance, security.

Available tools: ${Object.keys(ToolRegistry).join(', ')}
`;
```

### Data Analyst Agent
```javascript
const AGENT_INSTRUCTION = `
You are a data scientist specializing in business intelligence.

Your approach:
1. Load and validate data
2. Perform exploratory analysis
3. Identify trends and anomalies
4. Generate visualizations
5. Provide actionable recommendations

Focus on:
- Statistical significance
- Data quality issues
- Clear visualizations
- Business impact

Save all outputs as structured reports with charts.

Available tools: ${Object.keys(ToolRegistry).join(', ')}
`;
```

## Provider Usage Examples

### Local (Ollama default)
```bash
node agent.js "Summarize this repo's purpose" --yolo
# Or explicit model prefix for Ollama
node agent.js "Write a plan for the agent" --model ollama:gpt-oss --yolo
```

### OpenAI
```bash
export OPENAI_API_KEY=sk-...
node agent.js "Draft a product brief" --model openai:gpt-5-mini --yolo
# Or prompt and save to .env
node agent.js "Draft a product brief" --provider openai --model gpt-5-mini --save-keys --yolo
```

### Anthropic
```bash
export ANTHROPIC_API_KEY=sk-ant-...
node agent.js "Create a lightweight research report" --model anthropic:claude-sonnet-4-5 --yolo
```

### Gemini
```bash
export GEMINI_API_KEY=google-...
node agent.js "Outline a blog about vector DBs" --model gemini:gemini-2.5-flash --yolo
```

## How the Agent Chooses a Provider
- Best default: Ollama — zero cost and on‑device by default
- Explicit control: prefer `--provider` or model prefixes
- Light inference: obvious model names route to vendor; otherwise Ollama

## UX & Safety Notes
- Key prompting is TTY‑only; in CI/containers use env vars or pass `--*-key`
- `--save-keys` writes to local `.env` in the working directory — do not commit secrets
- Providers return a unified shape: `{ content, done }`

## Checklist for Agent Creation

- [ ] Identified agent purpose and domain
- [ ] Implemented necessary tools
- [ ] Added tool validation and error handling
- [ ] Customized agent instructions
- [ ] Included tool usage examples in instructions
- [ ] Defined output format expectations
- [ ] Tested with sample tasks
- [ ] Verified error handling works
- [ ] Ensured outputs are concise and useful
- [ ] Added any domain-specific logic

## Remember

1. **Start Simple**: Implement basic tools first, add complexity gradually
2. **Test Iteratively**: Test each tool as you build it
3. **User Focus**: Always consider what the end user needs
4. **Safety First**: The --yolo flag exists for a reason
5. **Be Helpful**: If a tool doesn't exist, create it with define_tool

When complete, the agent should be a self-contained, single-file solution that can be run immediately with:

```bash
node agent.js "User's task" --yolo
```

### Tool Discovery
List all tools: `<<tool:help {}>>`
See one tool’s signature & example payload: `<<tool:help {"tool":"read_file"}>>`
