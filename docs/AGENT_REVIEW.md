# Agent review and merge gate

Every PR into `main` or `dev` requires a passing `agent-review/main` or
`agent-review/dev` status respectively, plus `checkmake`, `shellcheck`,
`luacheck`, `pyright`, and `tests` checks. PRs, up-to-date branches,
resolved conversations, and linear history remain required. Mandatory human
approvals and mandatory code-owner approvals are disabled. CODEOWNERS still
identifies ownership; human reviews remain welcome.

The agent reviews the change, fixes or reports actionable findings, and records
the outcome on the exact reviewed commit. This works when the agent and PR
author use the same GitHub account: the record is a `COMMENT` review plus a
commit status, not a GitHub `APPROVE` review or an independent human approval.

## Review first

Before reviewing, capture the PR head and current base. Inspect the complete
effective diff, relevant repository guidance, behavior changes, and validation.
Do not treat passing CI as a completed code review. A pass requires no unresolved
actionable findings. Record blocking findings as a failure and review the new
commit after they are fixed.

Save the completed review to a Markdown file outside the checkout. Include the
scope, findings or explicit absence of findings, checks, and material limits.
Do not create an empty success report to satisfy branch protection.

## Publish the completed review

Use an authenticated `gh` CLI with repository write permission. From a trusted
checkout containing the publisher:

```sh
repo=raelldottin/dotfiles
printf 'Pull request number: '; IFS= read -r pr
head="$(gh pr view "$pr" --repo "$repo" --json headRefOid --jq .headRefOid)"
base_ref="$(gh pr view "$pr" --repo "$repo" --json baseRefName --jq .baseRefName)"
base="$(gh api "repos/$repo/git/ref/heads/$base_ref" --jq .object.sha)"
```

Review those commits and save the report, for example at
`/tmp/dotfiles-pr-review.md`. Keep the captured SHAs; if the diff changes, perform
a fresh review instead of merely recapturing values to make publication pass.

```sh
python3 agent_review.py "$pr" --repo "$repo" \
  --expected-head "$head" --expected-base "$base" \
  --result pass --body-file /tmp/dotfiles-pr-review.md
```

Use `--result fail` for blocking findings. The command exits 0 for a published
pass, 1 for a published failure, and 2 for a publication or validation error.

The publisher validates the open PR and live base branch, sets the target's
`agent-review/<branch>` status pending, posts the report on the reviewed commit,
then validates the head, base commit, and target branch again before recording
success or failure. Publication errors attempt to mark that gate as error,
including when the initial pending write fails. The status links to the review.
If GitHub rejects both writes, an earlier status can remain; stop and inspect
the remote gate after any publisher error before attempting a merge.

`agent_review.py` is a publisher, not a code-analysis engine. The status is an
operator attestation by a repository writer; it does not prove reviewer
independence. Other repository writers can also publish commit statuses.
Statuses are shared by commit and context: the branch suffix prevents a `dev`
review from satisfying `main`. Multiple PRs with the same head and target share
the gate, and the latest published result wins. Serialize review publication
for that head/target; the publisher is not a concurrency lock. A status does not
enforce PR-number or base-SHA provenance after publication.

## Merge and subsequent pushes

After the review and required CI checks pass:

```sh
gh pr merge "$pr" --repo "$repo" --squash --match-head-commit "$head"
```

A new head SHA needs a new review status; an old pass does not cover a later
push. If the base advances, refresh the branch when required and review the
resulting diff. The publisher checks base changes during publication; GitHub's
strict status-check rule keeps outdated branches from merging afterward.

Use normal merges. An administrator override requires the user's explicit
authorization for the particular PRs; authorization for earlier PRs is not a
standing exception.

For promotion to `main`, create a release branch from current `main` and apply
the reviewed integration commits. Review and validate that release branch and
publish its own `agent-review/main` status. Raw `dev`-to-`main` PRs can have stale
ancestry after squash merges, even when the file trees match.
