# Hugo Factory

A software factory: prompt-defined agents that take work from intake to pull
request. Each supported tool has its own copy of the agents, in that tool's
native format, with models chosen for that tool:

| Folder | For |
| --- | --- |
| `claude/agents/` | [Claude Code](https://code.claude.com) |
| `codex/` | [Codex CLI](https://github.com/openai/codex) |
| `copilot/agents/` | [GitHub Copilot CLI](https://github.com/github/copilot-cli) |

Read a role's file for what it actually does.

| Role | Does |
| --- | --- |
| `hugo` | Talks to you, and dispatches the other roles. Never edits code. |
| `triage` | Researches and reproduces the request, and creates or updates the issue. |
| `plan` | Interviews you, writes the plan, and records it on the issue. |
| `implement` | Makes the change, verifies it, and opens the PR. |
| `review` | Reviews the PR adversarially, and reports findings to Hugo. |

## Requirements

- At least one of Claude Code, Codex CLI, or GitHub Copilot CLI.
- Bash, for the install script.
- Access to the repository's forge and issue tracker from that tool (for
  example the `gh` CLI or an MCP server), so the agents can open PRs and
  update issues.

## Install

Clone this repository, then run the install script from the project you want
to use the factory in:

```bash
./install.sh
```

It asks where to install the agents:

- **Project** (the default): into the current project (its git root, or the
  current directory outside a git repository), so you can commit them and
  share them with your team.
- **Global**: into your home directory, so they are available in every
  project.

| Tool | Project | Global |
| --- | --- | --- |
| Claude Code | `.claude/agents/` | `~/.claude/agents/` |
| Codex CLI | `.codex/agents/`, plus the Hugo profile globally | `~/.codex/agents/` and `~/.codex/hugo.config.toml` |
| Copilot CLI | `.github/agents/` | `~/.copilot/agents/` |

It installs for every supported tool on your `PATH`. To install for specific
tools only, name them: `install.sh claude codex`.

| Option | Does |
| --- | --- |
| `-g`, `--global` | Install globally, without asking. |
| `-p`, `--project` | Install into the current project, without asking. |
| `-y`, `--yes` | Don't ask; install into the current project unless `-g` is given. The script also doesn't ask when its input isn't a terminal. |
| `--link` | Symlink the files instead of copying them, so a `git pull` of this repository updates the installed agents. Don't commit symlinked agents to a project; they point into your clone. |

By default the script copies the files, so run it again after you pull
changes. It overwrites installed copies of these agents, and doesn't touch
other files.

Codex loads project agents only in a trusted project. Trust the project when
Codex asks, or add it under `[projects]` in `~/.codex/config.toml`. Codex reads
profiles only from its home directory (`$CODEX_HOME`, by default `~/.codex`),
so Hugo's profile is always installed there, even for a project install.

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
project's `.claude/settings.json`. Hugo and review have no `Write`/`Edit`
tools, so Hugo must delegate code changes and review can't fix what it
reviews.

### Codex CLI

Codex can't start a session as a custom agent, so Hugo is a Codex profile
instead. The profile sets Hugo's model and gives the session Hugo's
instructions:

```bash
codex -p hugo
```

Hugo then spawns `triage`, `plan`, `implement`, and `review` from the
project's `.codex/agents` or from `~/.codex/agents`. Spawned agents take
their sandbox from the session, so start it with write access (the default
`workspace-write` is enough). On Codex, the rules against Hugo and review
editing code are enforced only by their instructions.

### GitHub Copilot CLI

```bash
copilot --agent hugo
```

You can also run `/agent` inside an interactive session and choose `hugo`.
The other roles are hidden from that picker, because only Hugo dispatches
them. Hugo's and review's tool lists leave out `edit`, so Hugo must delegate
code changes and review can't fix what it reviews.
