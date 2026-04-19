# Automation — run agents on a schedule or trigger

Your agents are already CLI programs (`node my-agent.js "task" --yolo`). Any scheduler can call them. This folder gives you the glue — an entrypoint, lock files, logging, and ready-to-edit launchd templates — so you can skip the plumbing and get to the recipe.

## What's in here

```
automation/
├── invoke-agent.sh                 # Universal entrypoint (call this, not node directly)
├── launchd/
│   ├── timer.plist.template        # Run every N seconds
│   ├── calendar.plist.template     # Run at a specific time (daily/weekly)
│   └── folder-watch.plist.template # Run when a file appears in inbox/
├── inbox/                          # Drop files here to trigger a run (watched pattern)
├── outbox/                         # Agents write their output here
├── logs/                           # Rotated per-agent run logs (last 20)
└── .locks/                         # Runtime lock files (auto-cleaned)
```

## Why `invoke-agent.sh` instead of calling node directly

It handles the things every scheduler gets wrong on first try:

- **Loads `.env` from the repo root** — launchd starts with a minimal environment (no `ANTHROPIC_API_KEY`, no `PATH`) so bare `node my-agent.js` fails in 40 different ways
- **Per-agent lock file** — if a run is still going when the next tick fires, the second run exits 2 instead of stomping state
- **Log rotation** — keeps the last 20 runs per agent under `logs/<agent>-<timestamp>.log`, drops older ones
- **Structured exit codes** — 0/1/2/126/127 so schedulers can react (retryable vs fatal)

Use:

```bash
./invoke-agent.sh my-agent.js "task text" --yolo
./invoke-agent.sh --cwd /abs/path/to/project my-agent.js "task" --yolo
```

## Recipe 1 — daily/weekly schedule (launchd)

**Use case:** "Every morning at 9am, generate a briefing and email me."

```bash
# 1. Copy the calendar template
cp launchd/calendar.plist.template \
   ~/Library/LaunchAgents/ee.agent-builder.briefing.plist

# 2. Edit the plist
#    - Label:            ee.agent-builder.briefing
#    - Replace __REPO_ABS_PATH__ with the absolute path to your agent-builder checkout
#    - Replace __AGENT_FILE__    with e.g. briefing.js
#    - Replace __TASK__          with e.g. "Generate today's briefing"
#    - Adjust Hour/Minute (default 09:00)

# 3. Load it
launchctl load ~/Library/LaunchAgents/ee.agent-builder.briefing.plist

# 4. Verify
launchctl list | grep briefing

# 5. Test-fire it right now (optional)
launchctl start ee.agent-builder.briefing

# 6. Tail the log
tail -f automation/logs/briefing-*.log
```

To remove: `launchctl unload ~/Library/LaunchAgents/ee.agent-builder.briefing.plist`.

## Recipe 2 — timer, every N minutes (launchd)

Use the same flow with `timer.plist.template`. Edit the `StartInterval` integer (seconds).

```
60      every minute
300     every 5 minutes
3600    hourly
86400   daily
```

Good for: polling a feed, watching a metric, pinging a status endpoint via the agent.

## Recipe 3 — "drop a file, agent runs" (folder-watch + inbox/)

**Use case:** "I want to say something to my agent from my phone / Siri / the share sheet / anywhere that can write a file."

The launchd `WatchPaths` key fires whenever anything changes inside `inbox/`. Every upstream trigger you can think of ultimately writes a file — which means they all feed the same agent through one uniform interface.

```bash
cp launchd/folder-watch.plist.template \
   ~/Library/LaunchAgents/ee.agent-builder.inbox.plist
# Edit: Label, __REPO_ABS_PATH__, __AGENT_FILE__
launchctl load ~/Library/LaunchAgents/ee.agent-builder.inbox.plist
```

**Build your inbox agent.** Copy the stub and paste this as the `AGENT_INSTRUCTION` + `defaultTask`:

```javascript
// In CONFIG:
defaultTask: 'Process all pending files in ./automation/inbox/',

// AGENT_INSTRUCTION:
const AGENT_INSTRUCTION = `
You are the inbox processor for this workspace. On every run:

1. list_files in ./automation/inbox/ — ignore entries starting with "." (like .gitkeep, .processed/)
2. For each file found:
   a. read_file the full contents; treat them as a user request to you
   b. Do the work the request asks for (use web_search, fetch_url, MCP tools, any skill — whatever fits)
   c. write_file the response to ./automation/outbox/<timestamp>-<input-basename>.md
      Format: a short YAML header (source, processed_at) plus the response
   d. Move the processed input into ./automation/inbox/.processed/ using write_file + delete_file
      (read original, write to the .processed path, then delete the original)
3. If no files are pending, call finish_task with "inbox empty" and stop — do not wait or loop

Rules:
- Never touch files outside ./automation/inbox/, ./automation/outbox/, or ./automation/inbox/.processed/
- If a request needs a capability you do not have, write an error note to outbox and still move the input — never let one bad request block the queue
- Pick a sensible default if the request is ambiguous; state the assumption in the response

Call finish_task when the inbox is drained (or on any fatal error) with a summary of what you processed.
`;
```

Create the agent:

```bash
cp agent.stub automation/inbox-agent.js
# Paste the AGENT_INSTRUCTION + defaultTask above into the file.
```

Test it:

```bash
echo "What's the weather in Tallinn?" > automation/inbox/test.txt
./automation/invoke-agent.sh inbox-agent.js --yolo
# Check automation/outbox/ for the result.
```

## Recipe 4 — iMessage / Siri / Shortcuts → inbox (recommended)

This is the macOS-native way to talk to your agent without writing any extra code. Everything flows through `inbox/` + `folder-watch.plist`.

Build a Shortcut once, wire it to any trigger you like.

### Build the Shortcut (2 minutes)

1. Open **Shortcuts** app → **+** (new Shortcut) → name it "Ask Agent"
2. Add action: **Ask for Input** (Text) — this is what you dictate or type
3. Add action: **Get the file at path** — path: `/Users/YOU/path/to/agent-builder/automation/inbox/`
   - Actually simpler: use **Append Text to File**. Pick a unique filename template:
4. Add action: **Append Text to File** — configure:
   - Text: `Provided Input` (from step 2) + "\n"
   - File path: `/Users/YOU/path/to/agent-builder/automation/inbox/shortcut-[Current Date, ISO 8601].txt`
   - If file does not exist: Create it

That's it. Run the Shortcut → it writes a file → launchd fires `inbox-agent.js` → output shows up in `outbox/`.

### Wire to a trigger

Pick any of these; they all invoke the same Shortcut:

| Trigger | Setup |
|---|---|
| **"Hey Siri, ask agent"** | Shortcuts auto-exposes the name as a Siri phrase. Just say it. |
| **Share sheet from Messages** | Shortcut Details → check "Use with Share Sheet". In Messages, select text → share → "Ask Agent". |
| **NFC tag** | Shortcuts app → Automation tab → "Create Personal Automation" → NFC → scan a tag → select the Shortcut. Tap phone on tag = ask agent. |
| **Focus mode start** | Automation tab → "When Focus changes" → select the Shortcut (e.g. run daily briefing when "Work" Focus turns on). |
| **Message from specific contact** | Automation tab → "Message" → specify contact → select the Shortcut. Useful for an always-on assistant triggered by a trusted sender. |
| **Time of day** | Automation tab → "Time of Day" → select time + Shortcut. (Equivalent to the calendar.plist recipe but defined in Shortcuts.) |
| **Location** | Automation tab → "Arrive" or "Leave" → location → Shortcut. |
| **Manually from menu bar / Dock / keyboard shortcut** | Shortcut Details → "Pin in Menu Bar" / "Use as Quick Action" / assign ⌘ shortcut. |

### Return the response to your phone

The simplest pattern: have the inbox agent call `fetch_url` at a webhook that posts back to you (Pushover, ntfy.sh, your own endpoint). Allowlist the host first:

```bash
# In the agent's CONFIG:
networkAllowlist: [
  'duckduckgo.com',
  'html.duckduckgo.com',
  'ntfy.sh',           // add your notification channel
],
```

Or: a second Shortcut runs on a 1-minute timer, reads the newest file in `outbox/`, shows it as a notification / reads it aloud / sends it via iMessage. Two-hop, no network at all.

## Recipe 5 — webhooks (advanced)

Expose `inbox/` to the public internet via a tunnel. Any service that can POST a webhook (Slack events, GitHub webhooks, IFTTT, Zapier) can now talk to your agent.

```bash
# One-line static tunnel (Cloudflare)
brew install cloudflared
cloudflared tunnel --url "http://localhost:8080" &

# Simple receiver that writes POST bodies to inbox/
while true; do
  { printf "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok"; } | \
    nc -l 8080 | \
    awk 'f{print} /^$/{f=1}' > automation/inbox/webhook-$(date +%s).txt
done &
```

Ship this receiver only on machines you trust. `invoke-agent.sh`'s lock file + `--yolo` preview gate still apply.

## Recipe 6 — Slack / Discord / Telegram

Don't bridge these yourself. Plug an MCP server into `mcp.json` and let the agent read/write messages directly:

```json
{
  "servers": {
    "slack":    { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-slack"],    "env": { "SLACK_BOT_TOKEN": "..." } },
    "telegram": { "command": "npx", "args": ["-y", "@some/mcp-server-telegram"], "env": { "TELEGRAM_BOT_TOKEN": "..." } }
  }
}
```

Now the agent's `slack_post_message`, `slack_list_channels`, etc. are just tools. Combine with a timer plist for "every 10 minutes, read messages in #alerts and triage."

## Troubleshooting

**launchd fires but nothing happens** — the agent probably can't find `node`. Check `logs/<agent>.stderr.log`. Fix: update the `PATH` in the plist's `EnvironmentVariables` to include where your node actually lives (`which node`).

**"Another run is in progress"** — an earlier run is stuck holding the lock at `automation/.locks/<agent>.lock`. If nothing is actually running (`pgrep -fl <agent>.js`), delete the lock dir: `rm -rf automation/.locks/<agent>.lock`.

**.env not loaded** — `invoke-agent.sh` sources `.env` from the agent's cwd (repo root by default). Make sure it exists and is readable by your user.

**Shortcut writes the file but launchd doesn't fire** — macOS sandboxing. Check **System Settings → Privacy & Security → Files and Folders → Shortcuts** and grant access to the folder containing `automation/inbox/`. Also confirm the launchctl job is loaded: `launchctl list | grep agent-builder`.

**Agent hangs** — `invoke-agent.sh` doesn't enforce a wall-clock timeout. Use launchd's `ExitTimeOut` (default 20s for graceful termination) or wrap the node call in `timeout 600 node ...` inside the script if you need a hard cap.

## What's intentionally NOT here

- **No resident daemon.** macOS already has launchd. Adding a Node process that stays resident to re-invent scheduling is the wrong shape for a zero-dep harness.
- **No Messages.db polling.** Reading `~/Library/Messages/chat.db` works but needs Full Disk Access, breaks across macOS releases, and reads *all* your messages. The Shortcuts path gives you the same capability without the privacy and fragility tax.
- **No built-in HTTP receiver.** Ships as a recipe (above) because the right listener for your threat model isn't the right listener for someone else's — local-only vs tunneled, auth vs no auth. Easier to show the pattern than bake a default.
