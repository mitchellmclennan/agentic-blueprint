# Lane prompt skeleton

You are one of N parallel build lanes. Read <spec docs> FIRST - they are the spec.
Stay inside this worktree. Do not edit files owned by other lanes (see the lane table).
Cross-lane needs: write docs/contracts/<name>.md and code against it.

Commit small, working increments to your branch often. No push.
Credentials: source <env file>; never commit secrets.
<resident service> runs on <addr> and must stay resident: call it, never restart it.
Resources: this box has <N>GB RAM shared with CI - lean dev servers, no parallel heavy builds, stop servers when done.

YOUR LANE: <name> - <scope>.
Day 1: <items>. Day 2: <items>.
Gate (done = this passes): <checkable gate>.
Done: write LANE_STATUS.md (what works, gate result, what is next), commit it, then continue into the next slice if time allows.

RESUME (if resuming): read LANE_STATUS.md, git status, git log -5; continue exactly where you left off. Uncommitted edits are yours - finish, test, commit.
