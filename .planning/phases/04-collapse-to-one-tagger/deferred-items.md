# Phase 4 — Deferred Items

Items surfaced during Phase 4 execution that Phase 4 does **not** fix, each with a named
destination. Recorded so that a later reader meets a decision rather than a silence.

---

## DEF-04-01 — the "beets has no `undo` command" constraint is stated unqualified in two files

**Surfaced:** 2026-09-04 (Phase 3, recorded in `stacks/selfhosted/arrs/beets.md` § *One correction
to this page's own § The recovery fence*). **Carried forward:** 2026-09-13 by plan 04-13.

**Destination: Phase 7** (the "undo exercised" criterion), or any earlier plan that is already
editing both files.

### What is wrong

`stacks/selfhosted/arrs/beets.md` records, dated and measured:

> *That section states, as a hard constraint, "beets has **no `undo` command** — that was checked
> against the live CLI, not assumed". **That remains true of the beets CLI and is narrower than it
> reads: beets-flask rc6 has a working `UNDO IMPORT`**, verified by use (destination gone, library
> 0 entries, source intact at 31 files). […] **Do not over-read the correction either** — it was
> exercised on one import, in a release candidate, and it reverses the import, not the tag writes
> made into the files. Phase 4 owns amending the constraint in `CLAUDE.md` and `PROJECT.md`.*

**No Phase 4 plan, `04-CONTEXT.md` decision or `04-RESEARCH.md` note covers that amendment**, and
both files still carry the bare claim, verified present on 2026-09-13:

| File | Line | Text |
|---|---|---|
| `CLAUDE.md` | 152 | `- **Reversibility**: **beets has no ` + "`undo`" + ` command** — verified against the live CLI. …` |
| `.planning/PROJECT.md` | 187 | `- **Reversibility**: **beets has no ` + "`undo`" + ` command** — verified against the live CLI. …` |

### Why plan 04-13 did not fix it

- **Mandate.** 04-13's `files_modified` is exactly one file, `stacks/selfhosted/arrs/beets.md`.
  Amending two further files — one of them the repo-root agent contract — from a closure/interim
  plan would be an unmandated edit, the same call plan 04-05 made about the host `.env` files.
- **`CLAUDE.md:152` is generated.** It sits inside the `<!-- GSD:project-start -->` … `project-end`
  region, whose source is `.planning/PROJECT.md`. Hand-editing only `CLAUDE.md` reverts on the next
  regeneration — the F15 defect class plan 04-04 had to solve for the `stack` region. **Both files
  must be amended in the same edit, PROJECT.md first**, and parity proven, exactly as 04-04 did.

### What the amendment should say

Keep the original wording standing (it is correct about the CLI) and qualify it in-band and dated,
in the 02.1-11 / 04-04 shape. Three things must survive the edit, because dropping any one of them
turns a correction into a new overstatement:

1. **beets' CLI still has no `undo`.** Nothing about the fence changes: a `library.db` copy alone
   cannot reverse an import, and a ZFS rollback alone leaves `incremental` state claiming the work
   is done. Roll back the tree and the database together or neither.
2. **beets-flask rc6's `UNDO IMPORT` works** — exercised once, on one import, in a release
   candidate.
3. **It reverses the import, not the tag writes made into the files.** This is the half most likely
   to be lost in a paraphrase, and it is the half that matters for a library with no other undo.

**Dependency worth noting:** beets-flask is not stood up until **Phase 5**. Amending before then
records a mechanism the estate does not yet run. That is acceptable — the claim being corrected is
about what is *true of beets*, not about what this estate has deployed — but Phase 7 is the natural
home because it is where the mechanism is actually exercised.
