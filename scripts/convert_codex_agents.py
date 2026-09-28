#!/usr/bin/env python3
"""Convert agents/<role>/agent.md specs into Codex CLI custom-agent TOML files."""
import json
import pathlib
import re
import sys

# Hugo runs as the main session (see install-codex.sh), not as a spawnable agent.
ORCHESTRATOR = "hugo"


def toml_multiline(text: str) -> str:
    """Escape text for a TOML basic multi-line string."""
    return text.replace("\\", "\\\\").replace('"""', '""\\"')


def convert(src_dir: pathlib.Path, dest_dir: pathlib.Path) -> None:
    dest_dir.mkdir(parents=True, exist_ok=True)
    for role_dir in sorted(src_dir.iterdir()):
        agent_md = role_dir / "agent.md"
        if not agent_md.is_file() or role_dir.name == ORCHESTRATOR:
            continue

        role = role_dir.name
        text = agent_md.read_text()
        if not text.startswith("---\n"):
            raise ValueError(f"{agent_md} must start with a '---' frontmatter fence")
        _, frontmatter, body = text.split("---", 2)

        match = re.search(r"^description:\s*(.+)$", frontmatter, re.MULTILINE)
        if not match:
            raise ValueError(f"{agent_md} is missing a description field")
        description = match.group(1).strip()

        # A JSON string literal is also a valid TOML basic string.
        lines = [
            f"name = {json.dumps(role)}",
            f"description = {json.dumps(description)}",
            f'developer_instructions = """\n{toml_multiline(body.strip())}\n"""',
        ]

        out_path = dest_dir / f"{role}.toml"
        out_path.write_text("\n".join(lines) + "\n")
        print(f"wrote {out_path}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: convert_codex_agents.py <agents-src-dir> <dest-dir>", file=sys.stderr)
        raise SystemExit(1)
    convert(pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]))
