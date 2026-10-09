# Unattended runs

Bypass mode (`--dangerously-skip-permissions`) runs every action without asking and skips safety checks. Use it only where a mistake or an attack can't reach anything you care about: a container or a VM with egress filtering. These settings refuse bypass mode on your computer.

## In a container

- Start from Anthropic's [reference dev container](https://code.claude.com/docs/en/devcontainer). Its firewall script limits outbound traffic.
- Run Claude as a non-root user.
- Don't mount your home folder, `~/.ssh` or cloud credential files. Use short-lived tokens scoped to one repository.

Claude can still change every file in the mounted project. It can also send anything inside the container, including Claude Code's credentials, to any host the network allows.

## Non-interactive runs

`claude -p` shows no trust dialog: a repository's hooks and `.mcp.json` servers run without asking. For a repository you didn't write, skip its settings:

```bash
claude -p "<task>" --setting-sources user
```

In CI, allow only what the job needs:

```bash
claude -p "run the test suite" --permission-mode dontAsk --allowedTools "Bash(npm test)" "Read"
```
