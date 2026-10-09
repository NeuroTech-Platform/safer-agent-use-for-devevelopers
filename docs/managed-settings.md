# Managed settings

A repository's `.claude/settings.json` can override your `~/.claude/settings.json`. Managed settings can't be overridden, and only root can change them. They apply to every account on the computer, including SandVault's.

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

## Stop repositories from loosening the sandbox

With `"allowUnsandboxedCommands": true`, a repository can still add `excludedCommands` and turn on weaker sandbox options. To stop that, set it to `false` in the managed file. Claude then can never retry a command outside the sandbox: you run blocked commands yourself.
