# Agent workflow

- Follow `docs/CONTRIBUTING.md` and `docs/AGENT_REVIEW.md` for delivery.
- Preserve unrelated local changes. Use an isolated worktree when necessary.
- Every PR into main or dev needs a completed review and a passing
  `agent-review/main` or `agent-review/dev` status for its target on its exact
  head, alongside the existing CI checks.
- Conduct a separate review pass before recording a pass. Passing CI alone is
  not a review. Report actionable findings, resolve them, and review the new
  commit before changing a failed gate to success.
- Publish the completed report with `agent_review.py`, supplying the reviewed
  head and base SHAs. Do not fabricate a report or reuse a pass for a new commit.
- The publisher records a COMMENT review and commit status. It does not submit
  an independent GitHub approval, and mandatory human approvals are disabled.
- Merge normally with an expected-head check after all gates pass. Do not use
  administrator overrides unless the user explicitly authorizes the particular
  PRs. Earlier one-time override authorizations do not apply to later work.
