# Claude Code Skills

A collection of custom skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Skills

### [grill-me](./grill-me)
Interview you relentlessly about a plan or design until every branch of the decision tree is resolved. Invoke with `/grill-me` when you want to stress-test an idea before building it.

### [frontend-design](./frontend-design)
Build distinctive, production-grade frontend interfaces with high design quality. Enforces bold aesthetic choices and avoids generic AI-generated aesthetics. Invoke with `/frontend-design`.

### [orchestrate](./orchestrate)
Decompose an engineering task into a parallel execution plan across 1–3 agents (Codex, Claude, Cursor). Generates `plan.md` and per-agent instruction files. Supports `--merge` to consolidate results between waves. Invoke with `/orchestrate <task>`.

### [pretext](./pretext)
Expert assistant for [`@chenglou/pretext`](https://github.com/chenglou/pretext) — high-performance, DOM-free text measurement and layout. Covers the full API, common patterns, and anti-patterns. Invoke with `/pretext`.

### [statusline](./statusline)
A custom status line script that shows real-time usage metrics: model, 5h/7d rate limit utilization, cost, context window usage, and reset time. See [`statusline/README.md`](./statusline/README.md) for setup.

## Installation

Copy any skill folder into your Claude Code skills directory:

```bash
# Install a single skill
cp -r grill-me ~/.claude/skills/

# Install all skills
cp -r grill-me frontend-design orchestrate pretext ~/.claude/skills/
```

For the statusline, follow the setup instructions in [`statusline/README.md`](./statusline/README.md).

## License

MIT
