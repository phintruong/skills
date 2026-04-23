# Statusline

A custom Claude Code status line that shows real-time usage metrics.

## What it displays

```
✨ Opus 4.7 | 5h ▰▰▱▱▱▱▱▱ 25% | 7d ▰▱▱▱▱▱▱▱ 12% | 💰 $3.42 | ▰▰▰▱▱▱▱▱ 38% 200k | ↻ 3:00 AM
```

- **Model** — current model name
- **5h** — 5-hour rate limit utilization (color-coded: green/yellow/red)
- **7d** — 7-day rate limit utilization
- **Cost** — account-wide credit usage in USD
- **Context** — context window usage bar + percentage + window size
- **Reset** — when the 5-hour window resets (local time)

## Requirements

- `jq` — for JSON parsing
- `curl` — for fetching usage data from the Anthropic API
- Claude Code OAuth credentials at `~/.claude/.credentials.json`

## Setup

1. Copy `statusline.sh` to `~/.claude/statusline.sh`

2. Add to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

## How it works

- Reads Claude Code's JSON status input from stdin
- Fetches usage data from the Anthropic API with a 60-second cache
- Outputs a single ANSI-colored line
- Colors shift from green to yellow (50%+) to red (80%+) as limits approach
