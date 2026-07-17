---
name: solution-decision-principles
description: >-
  Use whenever a solution is being decided or assessed — at a fork between approaches,
  while scoping or planning work, when designing an approach, when weighing any
  trade-off, and when reviewing a plan, design, or implementation for quality (your
  own or another's). Use before committing to an approach, not only while writing
  code. Reach for it the moment build "time", "effort", "quicker", "simpler to build",
  "to save time", "good enough for now", or "rather than the more involved X" enters
  the reasoning, and any time you are ranking or eliminating options.
---

# Solution decision principles

A growing set of guardrails for **any process that chooses, plans, designs, implements, or
reviews a solution**. Apply them when making a decision *and* when auditing one. More principles
will be added over time; treat each as a hard consideration, not a suggestion.

---

## Principle 1 — Suitability over effort

**Weight options by how well they fit the actual requirement** — correctness, robustness,
edge-case handling, security, fit to the real problem, and long-term maintainability. **Build
time and effort are NOT valid tie-breakers and must never outweigh suitability.**

### Why "time / effort" is an anti-pattern here
"This is quicker" / "simpler to implement" / "to save effort" almost always smuggle in a **human
timeline**. That intuition is calibrated to a person typing the code over days. An agent does not
have that constraint: the thorough, correct version and the shortcut usually cost the *user* roughly
the same wall-clock. So optimising the build for *your* effort optimises a cost that isn't real —
while the user still lives with the weaker solution forever. Choosing the lesser option to save
agent effort trades a permanent downside for an imaginary saving.

### What this does NOT mean
This is **not** licence to gold-plate, over-engineer, or expand scope. Suitability *includes*
simplicity: the most suitable solution is the **simplest one that fully meets the requirement**
(YAGNI still holds).

- ✅ "Simplest solution that fully does the job" — correct.
- ❌ "Easier to build, even though it's a worse fit / misses cases / is less robust" — the anti-pattern.

Effort-thrift is fine *only* when it costs suitability nothing. The moment a cheaper-to-build option
is also a worse option, suitability wins.

### Decision rule
At any fork:
1. Identify the **most suitable** option on the merits (ignore build effort entirely while ranking).
2. Pick it. If you feel pulled toward a lesser option, name the real reason:
   - A genuine **user-owned** constraint (they asked for a stopgap, stated a real deadline, or own a
     reversibility/runtime-cost trade-off) → legitimate, but it's **the user's call** — surface the
     trade-off and let them choose; don't silently downscope.
   - "It's less work for me / faster to write / more involved otherwise" → **not** a valid reason.
     Discard it and do the suitable thing.
3. If the suitable solution is large, do it, or if scope/constraints are genuinely unclear, **ask** —
   never unilaterally shrink the solution to save build effort.

### Red-flag phrases (catch yourself)
If any of these is the *justification* for an approach, stop and re-check against the decision rule:

> "for simplicity" · "to save time" · "quick and dirty" · "good enough for now" · "the easy way" ·
> "rather than the more involved…" · "this avoids the extra work of…" · "we can just…" ·
> "the minimal-effort option" · "cheaper to implement"

Present-tense best result, chosen on merit — not the version that was fastest to type.

---

<!-- Future principles go here as new "## Principle N — …" sections. -->
