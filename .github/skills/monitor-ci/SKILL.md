---
name: monitor-ci
description: >-
  Monitor a repository's CI (GitHub Actions) until it finishes, then report and
  assess the results. Use this whenever the user wants to watch a build or
  pipeline, check whether CI passed, or keep an eye on Actions runs — phrases
  like "monitor CI", "watch the build", "did the pipeline pass", "keep an eye on
  the checks", or right after you (or the user) push commits, open/update a PR,
  or merge to main. Also triggers when given a PR number, "on current PR" / "on
  PR XYZ", or a PR/run URL that may point at a different repo. When no target is
  given, infer it from context — the current branch's open PR if you're on a
  feature branch, otherwise main — and ask when it's genuinely ambiguous. Watches with
  `gh run watch` at a 10s interval, schedules wake-ups for long runs, judges the
  real result (the Terraform plan diff, test counts) rather than just the green
  check, and on failure digs into the logs to find the root cause — relating what
  happened to the changes that triggered the run.
user-invocable: true
---
<!--

  Auto-generated — do not edit manually.

-->
<!--

  Read by: VS Code Copilot, GitHub.com Coding Agent, Copilot CLI.
  NOT read by: Claude Code (see .claude/skills/ instead).

-->
# Monitor CI and report on the results

This skill watches a repository's CI (GitHub Actions) until it completes, then reports what happened. It is usually invoked as one step inside a larger task — right after committing, pushing, opening/updating a PR, or merging — so the real value is **assessment, not just status**: given the changes that triggered the run and the conversation so far, was the outcome what you expected? If something failed, was that failure expected, and if not, what caused it?

Use `gh` (the GitHub CLI) for everything. Assume `gh` is already authenticated; if a command returns an auth error, surface it and stop.

## Mindset

- **A green check is necessary, not sufficient.** The workflow conclusion only tells you the pipeline *ran* without erroring — not that it did what you intended. The real signal is the *semantic artifact*: a Terraform plan diff (`Plan: N to add…` vs `No changes`), test pass/fail counts, a coverage delta. A green run with the wrong diff is a failure; a red run that's the failure you deliberately caused is a success. Assess the artifact, not just the color — Step 5 makes this concrete.
- **Invoked mid-task:** you already know what changed and what you expected CI to do. Hold that expectation in mind and compare it against the actual result — that comparison is the point of the report.
- **Invoked cold** (a bare `/monitor-ci` with no relevant history): just report the facts objectively — pass/fail per workflow, and root cause on failure. Skip the "expected vs. observed" framing.
- **Never block the turn — never wait in the *foreground*.** CI takes minutes; use the non-blocking wait in Step 4 — and, while a run is still registering, the bounded wait in Step 2 — so the agent is freed and re-invoked when the run finishes. Foreground waiting is the part that fails: a bare `sleep N && <cmd>` is blocked outright, and a foreground poll loop is killed at the command timeout, burning the window and returning nothing. Backgrounded, that same loop is exactly right — it is the blocking that is the defect, not the sleeping.

## Step 1 — Resolve the target

Decide which repo and which runs to watch. When the target is **not** the current repo, thread a `-R owner/repo` flag through *every* `gh` command below.

When the user **names** a target, use this table:

| User says | Target |
| --- | --- |
| "current PR" / "this PR" | The PR for the current branch: `gh pr view --json number,headRefName,headRefOid,url,state` |
| "PR 123" / "on PR 123" | That PR in the current repo: `gh pr view 123 --json number,headRefOid,url,state` |
| A PR URL | Parse `owner/repo` and the number from the URL; use `-R owner/repo` |
| A run URL | Parse `owner/repo` and the run id from the URL; watch that run directly |

When the user says **nothing** about a target, infer it instead of defaulting blindly to main. Read the recent conversation and the repo state:

- Check the current branch: `git rev-parse --abbrev-ref HEAD`.
- **On a feature branch** — the user almost certainly means *this* branch's CI. If it has an open PR (`gh pr view --json number,headRefOid,url,state`), target that PR; otherwise target the branch's latest runs directly.
- **On the default branch (main/master)** — they mean main.
- **Recent conversation wins:** if you just pushed to a branch, opened/updated a PR, or merged to main in this session, that is the target — even if it differs from the current checkout.
- **When it's genuinely ambiguous** (e.g. detached HEAD, the branch and recent activity disagree, or several PRs are in play), briefly ask the user which target they mean rather than guessing.

## Step 2 — Find the run(s) and jobs

A trigger fans out in two ways, and you assess the leaves of both:

- **Several workflow runs** per push/PR (e.g. a build workflow and a separate lint workflow) — monitor all of them, not just one.
- **One run, many jobs** — a single run often expands into a **job matrix** (e.g. one job per environment). A single failed job still rolls up under one run id, so resolve and assess **per job**, not just per run: `gh run view <run-id> --json jobs`.

Resolve the run ids for the target:

- **Branch target (e.g. main):** find the newest commit that has runs, then list every run for it:
  - `gh run list --branch main --limit 1 --json headSha -q '.[0].headSha'` → `$SHA`
  - `gh run list --commit "$SHA" --json databaseId,workflowName,name,status,conclusion`
- **PR target:** take the head SHA (`headRefOid`) from `gh pr view`, then `gh run list --commit "$SHA" --json databaseId,workflowName,name,status,conclusion`. (`gh pr checks <pr>` is a handy at-a-glance view, but resolve concrete run ids so you can watch each one.)
- **After a rebase or force-push, verify the SHA.** Re-running an existing run re-executes its *original* commit, not the new head — a "re-run" tests the old code, which is rarely what you want after rewriting history. Confirm the run's `headSha` matches the commit you intend to test (`gh run view <id> --json headSha`); if it doesn't, find or trigger a run for the right SHA instead.
- **Already done?** If every run's `status` is `completed`, skip the wait and jump to Step 5.
- **No run, or a run that never fired?** If no run exists for the commit yet, it may still be registering — give it a bounded ~1–2 minute window before concluding that nothing fired, and wait for it **in the background**, never in the foreground. "Has a run appeared yet?" is a *single-notification* wait, so background a check that exits the moment one has: `until gh run list --commit "$SHA" --json databaseId -q '.[].databaseId' | grep -q .; do sleep 10; done` with `run_in_background: true`. That frees the turn and notifies you once, when it exits — the same shape as Step 4's backgrounded `gh run watch`. (**`Monitor`** is the tool for *one notification per event* — emitting each check as it lands, say — rather than a single "is it there yet"; if you reach for it here anyway, bound it with `timeout_ms` ~120000.) What must not happen is waiting in the **foreground**: a bare `sleep 60 && gh run list …` is blocked outright ("To wait for a condition, use Monitor"), and a foreground `until …; do sleep 10; done` or `for i in $(seq 1 30)` loop is killed at the command timeout, consuming the whole window and returning nothing. But some events **never trigger a workflow at all**: a force-push, for example, can register on the PR (`head_ref_force_pushed`) without firing anything. If the poll window closes with still no run for the SHA, don't wait forever — say so and surface re-trigger options: an empty commit (`git commit --allow-empty`), `workflow_dispatch` (`gh workflow run`), or closing/reopening the PR.

## Step 3 — Estimate how long it will take

This decides the wait strategy. Pull the duration of recent successful runs of the same workflow:

`gh run list --workflow "<workflowName>" --status success --limit 5 --json startedAt,updatedAt`

Compute `updatedAt − startedAt` and take a typical (or worst-case) value. Combine it with what you know from the conversation and the repo — a heavy integration/Terraform suite behaves very differently from a quick lint. Call the estimated remaining time `T`.

Duration is also a *result*, not only a wait input: when the change targets performance, compare the run/job/step duration against its baseline as part of the assessment in Step 5.

## Step 4 — Wait without blocking (hybrid)

Always pass **`--interval 10`** (10 seconds). The `gh run watch` default of 3s polls too aggressively and risks rate limiting; 10s is responsive enough and stays safely clear of limits.

Pick the mechanism by `T`:

**A. Background watch — the default.** Launch one watch per run as a background command. A backgrounded command re-invokes you the moment it exits, so you are notified exactly when CI finishes — no manual polling.

```
gh run watch <run-id> --interval 10 --compact      # run_in_background: true, one per run
```

Use this whenever `T` is short-to-moderate (say, ≲ 10–12 min) or the runs are already in progress and near done. Because the background watch re-invokes you on completion, do **not** also schedule wake-ups to poll it — that work is harness-tracked, so polling it is wasted effort.

**B. Scheduled re-check — for long runs.** When `T` is large (e.g. a 25-minute build) and holding an open watch process the whole time would be wasteful, let the *harness* idle through most of the dead time — a scheduled wake-up, not a blocking `sleep` — then check once, and only then start the background watch for the final stretch:

- **In a `/loop`** (you self-pace via `ScheduleWakeup`): schedule a wake-up at ~80–90% of `T` (`delaySeconds ≈ 0.85·T`, clamped to ≥60s), passing the same `/loop` input back. On wake, re-check status; if still running, start the background watch (mechanism A) for the tail.
- **Not in a `/loop`:** use mechanism A — the background watch already frees the turn and notifies you at completion, so a long run needs no special handling.

When watching multiple runs, wait until **all** of them have exited before reporting.

## Step 5 — Report and assess

Work in three passes: get the verdict, extract what actually happened, then judge it against what you expected.

**1. Verdict — per run *and* per job.**
`gh run view <run-id> --json status,conclusion,workflowName,displayTitle,startedAt,updatedAt,url,jobs`
Read `jobs[]` for the per-job conclusions; a matrix run rolls many results under one id, and you assess each.

**2. Extract the semantic artifact.** This is the step a naive monitor skips, and the one that matters most. The conclusion says the pipeline *ran*; the artifact says what it *did*. Find it before reaching for raw logs:

- **PR comment / job summary first.** Many pipelines post the meaningful result as a PR comment or a run/job summary — a Terraform plan extract, a test report, a coverage table. It's the fastest path and saves pulling megabytes of log: `gh pr view <pr> --comments`, or the run/job summary. Look here before anything else.
- **Then artifacts/logs** if the summary doesn't carry it.
- Pull out whatever encodes the real outcome — `Plan: X to add, Y to change, Z to destroy` vs `No changes`, test pass/fail counts, a coverage delta — and hold it next to what you predicted.

**3. Investigate failures *and* mismatches.** Dig in whenever a job is red **or** the artifact disagrees with your prediction:

- Start from the PR comment / summary and step-level outcomes (`jobs[].steps`).
- `gh run view <run-id> --log-failed` for the failing steps — but this **truncates** large logs (around 4 MB / ~14k lines), and the error is often past the cut. For the complete log, pull it from the jobs API: `gh api /repos/<owner>/<repo>/actions/jobs/<job-id>/logs > /tmp/job.log`.
- If the logs still don't explain it, read the changed code/files the run was built from.

Then assess against expectation (omit this framing entirely when invoked cold):

- **Green, artifact matches your prediction** → brief confirmation: which jobs, how long, link.
- **Green, but the artifact ≠ what you predicted → treat it as a failure** and report the mismatch. The same `No changes` is success for a refactor and a failure for a change that should have produced a diff — identical check, opposite meaning. This is the most important case to catch.
- **Green, but a step soft-failed** (`continue-on-error` / an "allow failing" toggle) → don't trust the color; report what the step actually did.
- **Red, and it's the failure you intended** (e.g. a test you knew would fail until a follow-up) → confirm it's *that* failure and nothing else broke.
- **Red, unexpected** → name the failing job/step, quote the key error line(s), give the most likely cause tied to the recent changes, and recommend a next step.
- **Performance-targeted change** → compare the run/job/step duration against its baseline; a green run that didn't get faster hasn't met the goal.

### Report template

```
CI <pass ✅ / fail ❌ / green-but-wrong ⚠️> — <repo> @ <branch-or-PR> (<short-sha>)

<one line per job: workflow › job — conclusion — key artifact (e.g. "Plan: 1 to add, 0 to change, 0 to destroy" or "142 passed") — duration — link>

Assessment:
<Did the result — conclusion AND artifact — match what we expected given the recent changes? One short paragraph.>

<On failure or artifact mismatch only:>
Problem: <failing job/step, or e.g. "green but plan shows No changes when a diff was expected">
Evidence:
  <key log line(s) or artifact excerpt>
Likely cause: <root cause, tied to what changed>
Suggested next step: <action>
```

## Edge cases & notes

- **Never run `gh run watch` without a run id.** Bare, it prompts interactively and will hang in an agent. Always resolve the id first (Step 2).
- **Conclusions other than success/failure:** `cancelled`, `skipped`, `startup_failure`, `timed_out`, `action_required` — report these plainly; don't try to root-cause them as failures unless that's clearly what's needed.
- **Soft-failed steps hide under a green job:** `continue-on-error` / "allow failing" toggles can leave a job green while a step inside it failed. When in doubt, check step-level outcomes (`gh run view <id> --json jobs` → `jobs[].steps`) or the artifact, not just the job conclusion.
- **Truncated logs:** `gh run view --log`/`--log-failed` cut off around 4 MB / ~14k lines — verbose suites (Terraform with `TF_LOG`/DEBUG) routinely run past it and the real error sits beyond the cut. Use the jobs-API fallback in Step 5 for the complete log.
- **No CI / no runs found:** say so clearly rather than waiting indefinitely.
- **Cross-repo:** thread `-R owner/repo` through *every* `gh` call — `run list`, `run view`, and `run watch`.
- **Auth:** `gh run watch` can't authenticate via fine-grained PATs (it needs `checks:read`). If watch fails on auth, fall back to periodic `gh run view` status checks — driven the same way as Step 2 (a backgrounded check, or `Monitor`), never a foreground loop.
- **Rate limiting:** stick to the 10s interval. If you still hit a secondary rate limit, back off to occasional `gh run view` checks rather than a tight watch loop.
