# Hugo Factory

Hugo is a set of coding agents that takes a piece of work from a rough request
to a reviewed pull request. You describe a bug or feature to Hugo. It
investigates, writes a plan you approve, has the change made and reviewed, and
hands you a PR to merge.

It works with [Claude Code](https://code.claude.com),
[Codex CLI](https://github.com/openai/codex), and
[GitHub Copilot CLI](https://github.com/github/copilot-cli). The agents are
plain prompt files, so there's nothing to build or run apart from the tool you
already use.

## How it works

You only ever talk to Hugo. Behind it are four specialist agents, each with
one job:

| Agent | Job |
| --- | --- |
| `hugo` | Talks to you and hands work to the other agents. Never edits code. |
| `triage` | Investigates the request, reproduces it, and opens or updates the issue. |
| `plan` | Asks you questions, writes the plan, and records it on the issue. |
| `implement` | Makes the change, checks it works, and opens the PR. |
| `review` | Reviews the PR adversarially and reports back to Hugo. Never edits code. |

A typical run goes triage, plan, implement, review. Hugo skips steps that
aren't needed: a one-line fix doesn't need a plan, and a link to an open issue
doesn't need triage. If review finds problems, Hugo sends the PR back to
implement and reviews it again.

Hugo stops and waits for you when:

- a plan is ready, because no code is written until you approve it
- it, or one of the other agents, has a question for you
- review raises something that's your call rather than a clear fix
- the PR is reviewed and ready for you to merge, which ends the run

Review runs on a different model from implement, so the code isn't checked by
the same model that wrote it.

## Quick start

```bash
git clone https://github.com/matt-major/hugo-factory.git
cd your-project
../hugo-factory/install.sh
claude --agent hugo    # or: codex -p hugo, copilot --agent hugo
```

Then tell Hugo what you want done, for example "the login page 500s when the
email has a plus sign", or paste a link to an issue.

## Requirements

- Claude Code, Codex CLI, or GitHub Copilot CLI (at least one)
- Bash, to run the install script
- Access to your forge and issue tracker from that tool, such as the `gh` CLI
  or an MCP server, so the agents can open PRs and update issues

## Installation

Run `install.sh` from inside the project you want to use Hugo in. It asks
whether to install into that project or globally:

- **Project** (the default) puts the agents in the project's git root, or the
  current directory if it isn't a git repository. Commit them to share Hugo
  with your team.
- **Global** puts them in your home directory, so they're available in every
  project.

| Tool | Project | Global |
| --- | --- | --- |
| Claude Code | `.claude/agents/` | `~/.claude/agents/` |
| Codex CLI | `.codex/agents/` | `~/.codex/agents/` |
| Copilot CLI | `.github/agents/` | `~/.copilot/agents/` |

By default the script installs for every supported tool it finds on your
`PATH`. To pick specific tools, name them:

```bash
install.sh claude codex
```

| Option | Effect |
| --- | --- |
| `-p`, `--project` | Install into the current project without asking. |
| `-g`, `--global` | Install globally without asking. |
| `-y`, `--yes` | Don't ask. Installs into the project unless `-g` is also given. The script also skips the question when it isn't run from a terminal. |
| `--link` | Symlink the files instead of copying them, so a `git pull` in your clone updates the installed agents. |

Don't commit symlinked agents. The links point into your clone and won't
resolve for anyone else.

### Updating

Pull this repository and run `install.sh` again, unless you installed with
`--link`. The script overwrites its own agent files and leaves everything else
alone.

### Codex notes

Codex only reads profiles from its home directory (`$CODEX_HOME`, which
defaults to `~/.codex`), so Hugo's profile, `hugo.config.toml`, always goes
there, even for a project install.

Codex also only loads project agents in a trusted project. Trust the project
when Codex asks, or add it under `[projects]` in `~/.codex/config.toml`.

## Usage

Start Hugo from inside the repository you want to work on.

### Claude Code

```bash
claude --agent hugo
```

To make Hugo the default in a project, add `"agent": "hugo"` to the project's
`.claude/settings.json`.

Hugo and review don't have the `Write` or `Edit` tools, so Hugo has to hand
code changes to implement, and review can't quietly fix what it's reviewing.

### Codex CLI

```bash
codex -p hugo
```

Codex can't start a session as a custom agent, so Hugo is a Codex profile. The
profile sets the model and loads Hugo's instructions, and Hugo then starts the
other agents from `.codex/agents/` or `~/.codex/agents/`.

The other agents inherit the session's sandbox, so it needs write access. The
default, `workspace-write`, is enough. Codex has no per-agent tool limits, so
Hugo and review stay out of the code only because their instructions tell them
to.

### GitHub Copilot CLI

```bash
copilot --agent hugo
```

You can also pick `hugo` from `/agent` in an interactive session. The other
agents are hidden from that list, since only Hugo should start them.

Hugo's and review's tool lists leave out `edit`, for the same reason as in
Claude Code.

## Customizing

Each tool has its own copy of the agents, written in that tool's format:

```
claude/agents/     Claude Code  (*.md)
codex/agents/      Codex CLI    (*.toml)
codex/hugo.config.toml          Hugo's Codex profile
copilot/agents/    Copilot CLI  (*.agent.md)
```

Every file sets its own model and instructions. Edit them to change models or
behaviour, then reinstall. If you change models, keep review on a different
model from implement.

The copies are maintained by hand. When you change how an agent behaves, make
the same change in all three folders.

## License

[MIT](LICENSE)
