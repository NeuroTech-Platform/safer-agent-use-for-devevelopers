# Shell commands and git

- Make every command legible to the user: one action per call, long option names, nothing the task doesn't need. Put a command on several lines, one option per line and each line but the last ending with ` \`, when one line would be hard to read, and always when the command needs the user's approval. A newline without `\` starts another command.
- The user approves each `gh` call, each `docker run`, `exec`, `build`, `buildx build` and `compose` call, and each command that runs code in a cluster or changes one: `kubectl apply`, `create`, `run`, `exec`, `delete`, `helm install`, `upgrade`, `uninstall`, `kind create`, `delete`, `ct install`, `cilium install`. Get what you need in as few calls as possible.
- Name the repository with `--repo owner/name`, or in the `gh api` path. Filter `gh` output with `--jq` instead of a pipe.
- Explore and Plan agents don't load this file. When you start one, put these rules in its prompt.
