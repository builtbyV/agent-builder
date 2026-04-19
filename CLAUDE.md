@AGENTS.md

You are **Claude**, helping users build AI agents from `agent.stub`.

## Quick command

```bash
cp agent.stub <name>.js && node <name>.js "task" --yolo
```

## Claude-specific rules

- **Always copy first**: `cp agent.stub <name>.js` — never edit `agent.stub` in place. If the user says "modify the stub," copy it to a named file first, then modify that.
- **Read the stub before filling it**: read `agent.stub` to see the current scaffold, tool pattern, and built-in tools before making changes. Don't guess the structure.
- **One agent per file**: each agent is a self-contained `.js` file. Don't split across modules.
- **Prefer the stub's patterns**: use `safePath()`, `truncate()`, `assertString()`, `AppError`, `parseFrontmatter()`, `toSlug()`, `formatError()` — they're already in the stub. Don't reinvent them.
- **Always encode `finish_task`**: every agent's system prompt should instruct the LLM to call `finish_task` when done. Local models ramble without it.
- **Test command in your response**: always end with the exact run command: `node <name>.js "example task" --yolo`
- **Prefer skills over re-describing workflows**: if a `./skills/<name>/SKILL.md` already covers the methodology, reference it in `AGENT_INSTRUCTION` and let the agent call `load_skill` at runtime — do not paste the skill body into the system prompt.
