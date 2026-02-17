# Ralph Wiggum Loop

An iterative AI agent loop that runs Claude Code repeatedly to build software autonomously, one small task at a time. Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/loop/).

## How It Works

1. You define a list of small tasks (user stories) in `prd.json`
2. You run `ralph.sh` which loops Claude Code with a fresh context each time
3. Each iteration, Claude reads what was done before, picks the next task, implements it, tests it, and commits
4. When all tasks are done, the loop stops

Each iteration gets a **fresh context window** — Claude relies on `prd.json`, `progress.txt`, and git history for continuity. This prevents hallucination from context bloat.

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed globally
- [jq](https://jqlang.github.io/jq/) for JSON parsing (`brew install jq`)
- Git initialized in your project

## Files

| File | Purpose |
|------|---------|
| `ralph.sh` | The bash loop that runs Claude Code repeatedly |
| `PROMPT.md` | Instructions Claude receives each iteration |
| `prd.json` | Your task list — user stories with `passes: true/false` |
| `prd.json.example` | Example task list you can copy and modify |
| `progress.txt` | Auto-populated log of what each iteration accomplished |

## Quick Start

### 1. Create your task list

Copy the example and edit it with your own tasks:

```bash
cp prd.json.example prd.json
```

Edit `prd.json` with your stories. Each story needs:
- `id` — unique identifier (e.g. `US-001`)
- `title` — short description
- `description` — what and why
- `acceptanceCriteria` — how Claude knows it's done
- `priority` — execution order (1 = first)
- `passes` — set to `false` (Ralph flips to `true` when done)

### 2. Customize the prompt

Edit `PROMPT.md` to match your project:
- Add your build/test commands
- Mention your tech stack
- Add any project-specific rules

### 3. Run the loop

```bash
./ralph.sh 20
```

The argument is the max number of iterations (default: 10). Ralph stops early when all stories are complete.

### 4. Monitor progress

In a separate terminal:

```bash
# Watch story completion status
watch -n2 'jq ".userStories[] | {id, title, passes}" prd.json'

# Check the progress log
cat progress.txt

# See commits Ralph made
git log --oneline
```

## Writing Good Stories

**Do:** Break work into small, focused tasks that fit in one context window.

```json
{
  "id": "US-001",
  "title": "Add priority column to database",
  "acceptanceCriteria": [
    "Migration adds priority column with default 'medium'",
    "Typecheck passes"
  ]
}
```

**Don't:** Write stories that are too big or vague.

```json
{
  "title": "Build the entire dashboard"
}
```

Good story size = one commit worth of work (add a field, create a component, wire up an endpoint).

## Using Ralph on an Existing Project

1. Copy `ralph.sh`, `PROMPT.md`, and `prd.json.example` into your project (e.g. `scripts/ralph/`)
2. Create a `prd.json` with your feature broken into small stories
3. Edit `PROMPT.md` to reference your project's build/test commands
4. Run `./ralph.sh 20` and let it work

## Tips

- **Always set a max iteration limit** as a cost safety net
- **Start small** — try 3-5 stories first to see how it works
- **Include test/build checks** in acceptance criteria so Claude verifies its own work
- **Check `progress.txt`** if something goes wrong — it logs what was tried
- **Stories run in priority order** — make sure dependencies come first

## References

- [Geoffrey Huntley - The Loop](https://ghuntley.com/loop/)
- [snarktank/ralph](https://github.com/snarktank/ralph)
- [Ralph Wiggum Guide by JeredBlu](https://github.com/JeredBlu/guides/blob/main/Ralph_Wiggum_Guide.md)
