#!/bin/bash
# Tests bin/sv-claude against a fake SandVault: fake sudo, sv and osascript.
# Run: tests/sv-claude.sh. It needs git and about two minutes.
set -u
HERE="$(cd "$(dirname "$0")" && pwd -P)"
T="$(cd "$(mktemp -d "$TMPDIR/svc-live.XXXXXX")" && pwd -P)"
mkdir -p "$T/bin" "$T/home" "$T/svhome" "$T/Shared/sv-$USER"
sed "s|^SHARED=.*|SHARED=\"$T/Shared/sv-\$USER\"|" "${SV_CLAUDE_SCRIPT:-$HERE/../bin/sv-claude}" > "$T/bin/sv-claude"
NOTES="$T/notifications"; : > "$NOTES"
export TROOT="$T"

cat > "$T/bin/sudo" <<'EOF'
#!/bin/bash
# Fake sudo: runs the command as the same user, with SandVault's home.
while [ $# -gt 0 ]; do case "$1" in -n|-H) shift ;; -u) shift 2 ;; *) break ;; esac; done
echo "INJECTED by SandVault's side" >&2
# SandVault's account can't read your folders: refuse to start in one.
case "$(pwd -P)/" in
    "$TROOT"/Shared/*|"$TROOT"/svhome/*) ;;
    "$TROOT"/*) echo "getcwd: cannot access parent directories: Permission denied" >&2; exit 1 ;;
esac
# Real sudo -H sets HOME, and env -i clears it. Here it stays the test's home.
if [ "$1" = /usr/bin/env ] && [ "${2:-}" = -i ]; then shift 2; exec /usr/bin/env -i HOME="$SVHOME" "$@"; fi
export HOME="$SVHOME"
exec "$@"
EOF
cat > "$T/bin/osascript" <<'EOF'
#!/bin/bash
for a in "$@"; do last="$a"; done
echo "$last" >> "$NOTES"
EOF
cat > "$T/bin/sv" <<'EOF'
#!/bin/bash
# Fake SandVault: "sv -x MODE COPY [-- args]". Runs the scenario in the copy.
cd "$3" || exit 1
step() { touch "$FLAGS/at-$1"; while [ ! -f "$FLAGS/go-$1" ]; do sleep 0.1; done; }
. "$SCENARIO"
EOF
chmod +x "$T/bin/"*

state_of() { echo "$T/home/Library/Caches/sv-claude/$(basename "$1")-$(printf '%s' "$1" | shasum | cut -c1-8)"; }
copy_of() { echo "$T/Shared/sv-$USER/work/$(basename "$1")-$(printf '%s' "$1" | shasum | cut -c1-8)"; }
run_bg() {  # run_bg DIR SCENARIO OUT [VAR=value...]: start a session in the background
    local dir="$1" sc="$2" out="$3"; shift 3
    ( cd "$dir" && env "$@" HOME="$T/home" SVHOME="$T/svhome" NOTES="$NOTES" SCENARIO="$sc" FLAGS="$FLAGS" \
        SV_CLAUDE_INTERVAL=0.3 PATH="$T/bin:$PATH" /bin/bash "$T/bin/sv-claude" > "$out" 2>&1 < /dev/null ) &
}
sv_sync() {  # sv_sync DIR ANSWERS...: run "sv-claude sync"
    local dir="$1"; shift
    (cd "$dir" && printf '%s\n' "$@" | HOME="$T/home" SVHOME="$T/svhome" NOTES="$NOTES" PATH="$T/bin:$PATH" \
        /bin/bash "$T/bin/sv-claude" sync 2>&1)
}
wait_for() { local i; for i in $(seq 1 120); do if eval "$1"; then return 0; fi; sleep 0.1; done; echo "      TIMEOUT: $1"; return 1; }
at() { wait_for "[ -f '$FLAGS/at-$1' ]"; }
go() { touch "$FLAGS/go-$1"; }
hold() { wait_for "mkdir '$1/cycle' 2> /dev/null" && echo $$ > "$1/cycle/pid"; }
release() { rm -rf "$1/cycle"; }
check() { if eval "$2"; then echo "PASS  $1"; else echo "FAIL  $1"; fi; }
show() { sed 's/^/      | /'; }
mkrepo() {  # mkrepo DIR: a repository with committed files, an ignored file and a hook
    mkdir -p "$1/src" "$1/.vscode" "$1/many"
    git -C "$1" init -q -b main; git -C "$1" config user.email t@t; git -C "$1" config user.name t
    for f in a b c d e f h; do seq 1 9 > "$1/$f.txt"; done
    for i in $(seq 1 25); do echo "$i" > "$1/many/f$i.txt"; done
    echo s > "$1/src/s.py"; echo '{}' > "$1/.vscode/settings.json"; echo '*.log' > "$1/.gitignore"
    printf 'base\0' > "$1/b.bin"; git -C "$1" add -A; git -C "$1" commit -qm init
    git -C "$1" remote add origin https://user:secret-token@github.com/org/repo.git
    printf '#!/bin/sh\necho hook\n' > "$1/.git/hooks/pre-commit"; chmod +x "$1/.git/hooks/pre-commit"
    echo SECRET > "$1/.env"; echo ignored > "$1/debug.log"; echo untracked > "$1/notes.txt"
}

echo "### A. One session: both ways, while it runs"
P="$T/proj"; mkrepo "$P"; S="$(state_of "$P")"; C="$(copy_of "$P")"
N0="$(git -C "$P" count-objects | cut -d' ' -f1)"
FLAGS="$T/flags-A"; mkdir -p "$FLAGS"
cat > "$T/scenario-A" <<'EOF'
step 1
echo claude1 >> a.txt
step 2
step 3
step 4
rm e.txt; mv f.txt g.txt
step 5
mkdir -p .vscode; echo '{"claude":1}' > .vscode/settings.json
ln -s /etc etc-link; ln -s ../../.. up-link; ln -s src/s.py ok-link; echo CLAUDE > .env; echo claude > debug.log
step 6
echo 'src/' >> .gitignore
step 7
for i in $(seq 1 25); do rm "many/f$i.txt"; done
step 8
step 9
step 10
echo last >> a.txt
EOF
run_bg "$P" "$T/scenario-A" "$T/A.out"; at 1
check "copy has your files"              "[ -f '$C/a.txt' ] && [ -f '$C/src/s.py' ] && [ -f '$C/notes.txt' ] && [ -f '$C/many/f25.txt' ]"
check "copy has no .env"                 "[ ! -e '$C/.env' ]"
check "copy has no ignored files"        "[ ! -e '$C/debug.log' ]"
check "copy has your history"            "[ \"\$(git -C '$C' log --format=%s -1)\" = init ] && [ \"\$(git -C '$C' symbolic-ref HEAD)\" = refs/heads/main ]"
check "copy's git sees your files as tracked" "[ -z \"\$(git -C '$C' status --porcelain -- a.txt src)\" ]"
check "origin without credentials"       "[ \"\$(git -C '$C' remote get-url origin)\" = https://github.com/org/repo.git ]"
check "your hooks stayed home"           "[ ! -e '$C/.git/hooks/pre-commit' ]"
go 1
echo "  Claude edits; you edit"
wait_for "grep -qx claude1 '$P/a.txt'";        check "Claude's edit reached you, live" "grep -qx claude1 '$P/a.txt'"
echo you1 >> "$P/b.txt"
wait_for "grep -qx you1 '$C/b.txt'";           check "your edit reached Claude, live"  "grep -qx you1 '$C/b.txt'"
at 2
hold "$S"; sed -i '' '2s/.*/2 claude/' "$C/c.txt"; sed -i '' '8s/.*/8 yours/' "$P/c.txt"; release "$S"
wait_for "grep -qx '2 claude' '$P/c.txt' && grep -qx '8 yours' '$C/c.txt'"
check "both edits to one file merged, both sides" "grep -qx '2 claude' '$P/c.txt' && grep -qx '8 yours' '$P/c.txt' && grep -qx '2 claude' '$C/c.txt' && grep -qx '8 yours' '$C/c.txt'"
go 2; at 3
hold "$S"; sed -i '' '5s/.*/5 claude/' "$C/d.txt"; sed -i '' '5s/.*/5 yours/' "$P/d.txt"
printf 'claude\0' > "$C/b.bin"; printf 'yours\0' > "$P/b.bin"; release "$S"
wait_for "grep -qx '5 yours' '$C/d.txt'"
check "same line: yours on both sides"   "grep -qx '5 yours' '$P/d.txt' && grep -qx '5 yours' '$C/d.txt' && ! grep -q claude '$P/d.txt'"
check "binary: yours on both sides"      "[ \"\$(tr -d '\\\\000' < '$P/b.bin')\" = yours ] && [ \"\$(tr -d '\\\\000' < '$C/b.bin')\" = yours ]"
wait_for "grep -q 'both changed d.txt' '$S/sync.log'"
check "log says how to get Claude's version" "eval \"\$(grep 'both changed d.txt' '$S/sync.log' | tail -1 | sed 's/.*Claude.s version: //')\" | grep -qx '5 claude'"
wait_for "grep -q 'both changed the same lines in proj' '$NOTES'"
check "you got a notification"           "grep -q 'both changed the same lines in proj' '$NOTES'"
go 3; at 4; go 4; at 5
wait_for "[ ! -e '$P/e.txt' ] && [ -f '$P/g.txt' ]"
check "Claude's delete and rename reached you" "[ ! -e '$P/e.txt' ] && [ ! -e '$P/f.txt' ] && [ -f '$P/g.txt' ]"
go 5; at 6; sleep 1.5
check ".vscode change not copied to you"  "grep -qx '{}' '$P/.vscode/settings.json'"
wait_for "grep -qx '{}' '$C/.vscode/settings.json'"
check "copy's .vscode set back to yours"  "grep -qx '{}' '$C/.vscode/settings.json'"
check "links out of the repo not copied"  "[ ! -L '$P/etc-link' ] && [ ! -L '$P/up-link' ]"
check "...and they stay in the copy"      "[ -L '$C/etc-link' ] && [ -L '$C/up-link' ]"
check "link inside the repo copied"       "[ -L '$P/ok-link' ]"
check "Claude's .env not copied"          "grep -qx SECRET '$P/.env'"
check "your ignored file untouched"       "grep -qx ignored '$P/debug.log'"
go 6; at 7; sleep 1.5
check ".gitignore edit deletes nothing"   "[ -f '$P/src/s.py' ]"
hold "$S"; go 7; at 8; release "$S"
wait_for "grep -q 'changes to 25 files in proj wait' '$NOTES'"
check "25 deletions held, you notified"  "[ -f '$P/many/f1.txt' ] && grep -q 'changes to 25 files in proj wait' '$NOTES'"
echo "  sv-claude sync, answering y:"; sv_sync "$P" y | show
check "deletions applied after review"   "[ ! -e '$P/many/f1.txt' ] && [ ! -e '$P/many/f25.txt' ]"
go 8; at 9
OUT2="$(cd "$P" && HOME="$T/home" SVHOME="$T/svhome" PATH="$T/bin:$PATH" /bin/bash "$T/bin/sv-claude" < /dev/null 2>&1)"
check "second start refused"             "printf '%s' \"\$OUT2\" | grep -q 'running already'"
rm "$P/h.txt"
wait_for "[ ! -e '$C/h.txt' ]";          check "your delete reached Claude" "[ ! -e '$C/h.txt' ]"
go 9; at 10; go 10; wait
check "Claude's last edit, at exit"      "[ \"\$(tail -1 '$P/a.txt')\" = last ]"
check "your git index untouched"         "[ -z \"\$(git -C '$P' diff --cached --name-only)\" ]"
check "SandVault's side can't write to your log or terminal" "! grep -q INJECTED '$S/sync.log' && ! grep -q INJECTED '$T/A.out'"
check "no object or ref added to your repo" "[ -z \"\$(git -C '$P' for-each-ref refs/keep refs/sync)\" ] && [ \"\$(git -C '$P' count-objects | cut -d' ' -f1)\" = '$N0' ]"
echo "  session output:"; show < "$T/A.out"

echo "### B. Next session: what you changed in between reaches the copy"
echo between >> "$P/a.txt"; FLAGS="$T/flags-B"; mkdir -p "$FLAGS"
printf 'step 1\n' > "$T/scenario-B"
run_bg "$P" "$T/scenario-B" "$T/B.out"; at 1
wait_for "[ \"\$(tail -1 '$C/a.txt')\" = between ]"
check "between-sessions edit in the copy" "[ \"\$(tail -1 '$C/a.txt')\" = between ]"
check "no stale file came back"          "[ ! -e '$P/e.txt' ] && [ ! -e '$P/many/f1.txt' ]"
go 1; wait

echo "### C. SV_CLAUDE_REVIEW=1: Claude's changes wait for sv-claude sync"
P="$T/rev"; mkrepo "$P"; S="$(state_of "$P")"; C="$(copy_of "$P")"; FLAGS="$T/flags-C"; mkdir -p "$FLAGS"
printf 'step 1\necho claude >> a.txt\nstep 2\n' > "$T/scenario-C"
run_bg "$P" "$T/scenario-C" "$T/C.out" SV_CLAUDE_REVIEW=1; at 1; go 1; at 2
echo you >> "$P/b.txt"; wait_for "grep -qx you '$C/b.txt'"
check "your edit reached Claude"         "grep -qx you '$C/b.txt'"
check "Claude's edit waits"              "! grep -qx claude '$P/a.txt'"
SYNC_OUT="$(sv_sync "$P" y)"; echo "  sv-claude sync, answering y:"; printf '%s\n' "$SYNC_OUT" | show
check "applied after review"             "grep -qx claude '$P/a.txt'"
check "nothing from SandVault's side in sv-claude sync" "! printf '%s' \"\$SYNC_OUT\" | grep -q INJECTED"
go 2; wait

echo "### D. Folder of repositories"
P="$T/ws"; mkdir -p "$P"; mkrepo "$P/repoA"; mkrepo "$P/repoB"; echo top > "$P/top.txt"; FLAGS="$T/flags-D"; mkdir -p "$FLAGS"
C="$(copy_of "$P")"
printf 'step 1\necho claude >> repoA/a.txt\necho claude >> repoB/a.txt\nstep 2\n' > "$T/scenario-D"
run_bg "$P" "$T/scenario-D" "$T/D.out"; at 1; go 1
wait_for "grep -qx claude '$P/repoA/a.txt' && grep -qx claude '$P/repoB/a.txt'"
check "both repositories synced"         "grep -qx claude '$P/repoA/a.txt' && grep -qx claude '$P/repoB/a.txt'"
check "top-level file stays home"        "[ ! -e '$C/top.txt' ]"
go 2; wait

echo "### E. Repository without commits, and a crashed run's lock"
P="$T/fresh"; mkdir -p "$P"; git -C "$P" init -q; seq 1 3 > "$P/a.txt"; FLAGS="$T/flags-E"; mkdir -p "$FLAGS"
S="$(state_of "$P")"; mkdir -p "$S/session"; echo 999999 > "$S/session/pid"
printf 'step 1\necho claude >> a.txt\n' > "$T/scenario-E"
run_bg "$P" "$T/scenario-E" "$T/E.out"; at 1; go 1; wait
check "synced, lock taken over"          "grep -qx claude '$P/a.txt'"
show < "$T/E.out"

echo "### G. Deletions spread over several syncs still add up"
P="$T/spread"; mkrepo "$P"; FLAGS="$T/flags-G"; mkdir -p "$FLAGS"
cat > "$T/scenario-G" <<'EOF'
step 1
for i in $(seq 1 15); do rm "many/f$i.txt"; done
step 2
for i in $(seq 16 25); do rm "many/f$i.txt"; done
step 3
EOF
run_bg "$P" "$T/scenario-G" "$T/G.out"; at 1; go 1; at 2
wait_for "[ ! -e '$P/many/f15.txt' ]"
check "15 deletions synced"              "[ ! -e '$P/many/f1.txt' ] && [ ! -e '$P/many/f15.txt' ]"
go 2; at 3
wait_for "grep -q 'changes to 10 files in spread wait' '$NOTES'"
check "the next 10 within a minute held" "[ -f '$P/many/f16.txt' ] && grep -q 'changes to 10 files in spread wait' '$NOTES'"
go 3; wait

echo "### H. Shallow clone: syncs, without history in the copy"
mkrepo "$T/origin-H"; P="$T/shallow"; git clone -q --depth 1 "file://$T/origin-H" "$P"; S="$(state_of "$P")"
FLAGS="$T/flags-H"; mkdir -p "$FLAGS"; printf 'step 1\necho claude >> a.txt\nstep 2\n' > "$T/scenario-H"
run_bg "$P" "$T/scenario-H" "$T/H.out"; at 1; go 1
wait_for "grep -qx claude '$P/a.txt'"
check "shallow clone syncs"              "grep -qx claude '$P/a.txt'"
check "log says why there is no history" "grep -q 'no history: shallow or partial clone' '$S/sync.log'"
go 2; wait

echo "### I. A failing step on SandVault's side shows its error"
P="$T/broken"; mkrepo "$P"; C="$(copy_of "$P")"; mkdir -p "$(dirname "$C")"; echo "not a folder" > "$C"
OUT5="$(cd "$P" && HOME="$T/home" SVHOME="$T/svhome" NOTES="$NOTES" SCENARIO=/dev/null FLAGS="$T" PATH="$T/bin:$PATH" /bin/bash "$T/bin/sv-claude" < /dev/null 2>&1)"
printf '%s\n' "$OUT5" | show
check "start refused, with the reason"   "printf '%s' \"\$OUT5\" | grep -q \"Couldn't prepare broken\" && printf '%s' \"\$OUT5\" | grep -q 'SandVault side: mkdir'"

echo "### J. Claude switches the copy's branch: its changes wait"
P="$T/branchy"; mkrepo "$P"
git -C "$P" switch -q -c feat; echo feat > "$P/b.txt"; git -C "$P" commit -qam feat; git -C "$P" switch -q main
FLAGS="$T/flags-J"; mkdir -p "$FLAGS"
cat > "$T/scenario-J" <<'EOF'
step 1
echo claude >> a.txt
step 2
git -c user.name=c -c user.email=c@c commit -qam "Claude's edit"
step 3
git checkout -q feat
step 4
EOF
run_bg "$P" "$T/scenario-J" "$T/J.out"; at 1; go 1; at 2
wait_for "grep -qx claude '$P/a.txt'"; go 2; at 3; sleep 1.5
check "commit of synced edits not held"  "! grep -q \"git state of branchy\" '$NOTES'"
go 3; at 4
wait_for "grep -q 'git state of branchy' '$NOTES'"
check "branch switch held, you notified" "[ \"\$(head -1 '$P/b.txt')\" = 1 ] && grep -q 'branch: feat' '$NOTES'"
SYNC_J="$(sv_sync "$P" y)"; echo "  sv-claude sync, answering y:"; printf '%s\n' "$SYNC_J" | head -6 | show
check "review names both branches"       "printf '%s' \"\$SYNC_J\" | grep -q 'The copy is on feat; your folder is on main'"
check "applied after review"             "[ \"\$(cat '$P/b.txt')\" = feat ]"
go 4; wait

echo "### F. Your account never touches the copy"
grep -n -E '"\$(COPY|CD)|\$COPY/|\$CD/' "${SV_CLAUDE_SCRIPT:-$HERE/../bin/sv-claude}" | show

if [ "${KEEP:-0}" = 1 ]; then echo "Test files kept: $T"; else rm -rf "$T"; fi
