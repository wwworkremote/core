# Release Branch Disposition

Before a public history rewrite, every local and remote feature branch must
have an explicit disposition. Do not infer that a branch is safe to delete
because a pull request is closed.

For each branch, record exactly one outcome:

- merged into `main` and verified in the release tree;
- cherry-picked into `main`, with the source commit recorded;
- intentionally closed as obsolete, with the reason recorded; or
- blocked, with an owner and next action.

Run the read-only audit before rewriting history:

```bash
bin/audit_public_release --json
```

The audit fails if any non-`main` local branch is not an ancestor of `main`.
Remote branch and pull-request disposition must be checked separately with
the hosting provider before deleting remote branches. A closed pull request
is not proof that its code was merged.
