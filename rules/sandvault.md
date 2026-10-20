# Git in a SandVault copy

- This folder, under `/Users/Shared/sv-*/work/`, is a copy of the user's folder, synced with it. The user's folder decides the branch. Don't switch branches, reset, rebase, pull, commit or push here; ask the user to do it. For another branch, add a worktree with `git worktree add`: it stays in the copy, and there you commit yourself and push with the user's approval.
- Explore and Plan agents don't load this file. When you start one, put these rules in its prompt.
