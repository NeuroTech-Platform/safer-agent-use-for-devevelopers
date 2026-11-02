# Managed settings

A repository's `.claude/settings.json` can override your `~/.claude/settings.json`. Managed settings can't be overridden, and only root can change them. They apply to every account on the computer, including SandVault's.

They also reach Cowork tasks in the Claude Desktop app, which read no `~/.claude/settings.json`. Cowork runs shell commands in its own virtual machine. On Windows, the `sandbox` block stops Cowork tasks with `Sandbox required but unavailable`: remove it from the Windows managed file if you need to use it.

## Install

From an admin account, in this repository's folder:

```bash
# macOS
sudo mkdir -p "/Library/Application Support/ClaudeCode"
grep -v '^[[:space:]]*//' settings.jsonc | sudo tee "/Library/Application Support/ClaudeCode/managed-settings.json" > /dev/null
# Linux, WSL2
sudo mkdir -p /etc/claude-code
grep -v '^[[:space:]]*//' settings.jsonc | sudo tee /etc/claude-code/managed-settings.json > /dev/null
```

Check: in Claude Code, run `/status`. `Setting sources` must include `Enterprise managed settings`.

Your `~/.claude/settings.json` still applies. Lists from both files are merged. For single values, the managed file wins.

## Run the no-email mod on managed computers

Where managed settings exist, or the login is a Team or Enterprise account, Claude Code's built-in guard passes over the `no-email` mod from `~/.claude/skills/`. It runs only as the organization's own mod: this repository is a plugin marketplace (`.claude-plugin/marketplace.json`), so copy it to a folder only administrators can write, and add to the managed file:

```json
{
  "extraKnownMarketplaces": {
    "safer-claude-use": { "source": { "source": "directory", "path": "/opt/safer-claude-use" } }
  },
  "enabledPlugins": { "no-email@safer-claude-use": true },
  "prependPlugins": ["no-email@safer-claude-use", "sec-default@builtin"]
}
```

Keep `sec-default@builtin` in the list: it is the guard. Check in a session with `claude --debug`: the log's `hooks module no-email@safer-claude-use loaded` line says `tier prepend`.

## Stop repositories from loosening the sandbox

With `"allowUnsandboxedCommands": true`, a repository can still add `excludedCommands` and turn on weaker sandbox options. To stop that, set it to `false` in the managed file. Claude then can never retry a command outside the sandbox: you run blocked commands yourself.
