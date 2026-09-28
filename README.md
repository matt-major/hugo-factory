# Hugo Factory

A software factory: prompt-defined agents that take work from intake to pull
request. Each role's full spec lives in `agents/<role>/agent.md` (frontmatter
`description` + a Markdown system prompt) — read those for what each agent
actually does.

| Role | Does |
| --- | --- |
| `hugo` | Talks to you, and dispatches the other roles. Never edits code. |
| `triage` | Researches and reproduces the request, and creates or updates the issue. |
| `plan` | Interviews you, writes the plan, and records it on the issue. |
| `implement` | Makes the change, verifies it, and opens the PR. |
| `review` | Reviews the PR adversarially, and reports findings to Hugo. |

## Requirements

- Bash, and Python 3 for the Codex install.
- At least one of: [Claude Code](https://code.claude.com),
  [Codex CLI](https://github.com/openai/codex), or
  [GitHub Copilot CLI](https://github.com/github/copilot-cli).
- Access to the repository's forge and issue tracker from that tool (for
  example the `gh` CLI or an MCP server), so the agents can open PRs and
  update issues.

## Install

```bash
scripts/install.sh <claude-code|codex|copilot|all>
```

This installs the agents into your user-level agent directory, so they are
available in every project:

| Platform | Installs to |
| --- | --- |
| Claude Code | `~/.claude/agents/<role>.md` |
| Codex CLI | `~/.codex/agents/<role>.toml`, plus `~/.codex/hugo.md` |
| Copilot CLI | `~/.copilot/agents/<role>.agent.md` |

Re-run after editing any `agents/*/agent.md` to keep the installed copies in
sync. The scripts convert each spec into the target platform's native format.
They overwrite the installed files each run, and they don't remove the files
of a role you have deleted.

### Use a different model for review

Review should run on a different model from implement, so that the review is
independent and a model isn't marking its own work. The installers don't set
models, so after you install, set one in the installed review agent:

- Claude Code: add `model:` to the frontmatter of `~/.claude/agents/review.md`.
- Codex: add `model = "..."` to `~/.codex/agents/review.toml`.
- Copilot: add `model:` to the frontmatter of `~/.copilot/agents/review.agent.md`.

Installing again overwrites these edits, so set the model again after each
install.

## Usage

In every tool, Hugo runs as the main session and you talk only to Hugo. Start
it from inside the repository you want to work on, then describe the work: a
bug, a feature, or a link to an existing issue. Hugo acknowledges the request,
and then:

- Asks you questions when it needs input.
- Waits for your approval of a plan before any code is written.
- Stops when it hands you a reviewed PR to merge yourself.

### Claude Code

```bash
claude --agent hugo
```

To make Hugo the default for a project, add `"agent": "hugo"` to that
project's `.claude/settings.json`. Hugo has no `Write`/`Edit` tools, so it
must delegate code changes to the other roles.

### Codex CLI

Codex can't start a session as a custom agent. Instead, pass Hugo's
instructions to the main session:

```bash
codex -c "developer_instructions=$(cat ~/.codex/hugo.md)"
```

A shell alias makes this easier:

```bash
alias hugo='codex -c "developer_instructions=$(cat ~/.codex/hugo.md)"'
```

Hugo then spawns `triage`, `plan`, `implement`, and `review` from
`~/.codex/agents`. Spawned agents take their sandbox from the session, so
start it with write access (the default `workspace-write` is enough). Hugo's
rule against editing code is enforced only by its instructions on Codex.

### GitHub Copilot CLI

```bash
copilot --agent hugo
```

You can also run `/agent` inside an interactive session and choose `hugo`.
Hugo's tool list leaves out `edit`, so it must delegate code changes to the
other roles.
