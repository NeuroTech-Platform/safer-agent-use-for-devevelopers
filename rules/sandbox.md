# Shell commands under the user's sandbox settings

- Don't `cd`. Name paths relative to the working directory, or as absolute paths. Claude Code can't check where a path after a `cd` leads, so the command can need the user's approval.
- `gh`, `docker ps`, `docker logs` and `docker exec` run outside the sandbox, but only when the call holds nothing else. Otherwise the call runs in the sandbox, where they fail; `gh` prints `failed to read configuration`. Run each as a call of its own: no `cd`, pipes, `;`, `&&`, file redirects or `$(...)`. If one failed in the sandbox, run it again that way. Don't ask to run it outside the sandbox.
- Name the repository with `--repo owner/name`, or in the `gh api` path. Filter `gh` output with `--jq` instead of a pipe.
- The user approves each `gh` and `docker exec` call. Get what you need in as few calls as possible.
- Explore and Plan agents don't load this file. When you start one, put these rules in its prompt.
