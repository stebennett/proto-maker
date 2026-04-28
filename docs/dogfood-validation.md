# Proto-maker dogfood validation plan

This is the **product-quality validation** plan. It is distinct from the canonical end-to-end test in [`docs/dogfood-walkthrough.md`](dogfood-walkthrough.md), which exercises every skill against a canned idea ("dark-mode toggle") and verifies that contracts pass. That test answers *does it run?*

This plan answers a different question: **does the output land?** Specifically — does the HANDOFF.md + handoff.zip that proto-maker produces from a real idea actually let an engineer estimate the work, and was the eight-stage experience worth the PM's time?

Run this BEFORE rolling proto-maker out beyond the maintainer. A successful canonical walkthrough is necessary but not sufficient.

---

## Goals

We are testing three hypotheses, in order of importance:

1. **HANDOFF.md is sufficient to estimate.** An engineer reading only `HANDOFF.md` plus the linked artifacts can T-shirt-size the work without having to ask the PM clarifying questions beyond the "Open questions" section.
2. **The three alternatives are meaningfully distinct.** The Designer subagent produces three different *angles* on the problem, not three wireframes with the same structure and different headings.
3. **Critique → evolution actually evolves.** The v2 prototypes (after critic + user-advocate + engineer feedback) are demonstrably better than v1, not just shuffled.

Plus an explicit goal of surfacing failure modes we didn't predict.

---

## Picking the idea

The dogfood idea must satisfy all of:

- **Real.** It solves an actual product problem someone has. Not a contrived example, not a re-statement of the dark-mode-toggle test.
- **Small.** Expressible in one or two sentences. The "smallest valuable version" should be something an engineer could ship in ≤2 weeks.
- **Low-stakes.** If proto-maker produces a bad handoff, no real harm. Do not dogfood on the most important roadmap item.
- **PM-led.** The person running proto-maker owns the decision about whether to build the idea. We are not doing market research on someone else's idea.
- **Has stakeholders.** At least one person other than the PM should give annotations during the review stage. Without this, the review loop isn't exercised.

And avoid all of:

- Already-decided ideas. Proto-maker is for shaping ideas; it cannot course-correct what's already locked in.
- Ideas with heavy backend or data dependencies. Wireframes cannot show those, and the Engineer subagent will flag everything as TBD, drowning the signal.
- Ideas requiring new personas. Run `/setup` once with a stable persona set; don't blur the validation by also testing setup-of-personas.

---

## Roles

A meaningful dogfood needs at minimum:

| Role | What they do | Notes |
|---|---|---|
| **PM (driver)** | Runs `/proto-maker`, answers the interviews, makes the calls. | Keeps a running log of awkward, slow, or surprising moments. |
| **Stakeholder(s)** (≥1) | Review prototypes via `/preview`. Leave annotations via the `?` button. | Don't coach them. Send them the URL and let them figure out the overlay. Their first reaction is data. |
| **Engineer** (1) | Receives `HANDOFF.md` + `handoff.zip`. Attempts to T-shirt-size the work. Reports what's missing for an estimate. | Should NOT have been involved in earlier stages — the handoff is the test. |

Minimum viable: PM + 1 stakeholder + 1 engineer. Smaller (PM playing all three) is OK for a first pass but skews every signal toward the PM's mental model.

---

## Run protocol

- Use a fresh ideas repo: `mkdir -p ~/scratch/dogfood-real && cd ~/scratch/dogfood-real`. Don't reuse the canonical-test directory.
- **Don't skip stages.** Even if a stage feels redundant, the test is the experience of all eight.
- **Don't override the kill verdict** unless you have a concrete reason that you can articulate in one sentence. If the critic recommends `kill`, that is data; honour it the first time.
- **Run `/iterate-prototype` at least once** even if the chosen alt feels ready. Otherwise stage 6 is unexercised.
- **Use real stakeholder feedback.** Don't paste the offline JSON yourself; let the stakeholder click through the prototype in their own browser, ideally on their own machine, and let them use either the `?` overlay (online) or paste their notes (offline).
- **Record timing.** Per stage, note start time and elapsed time. Where did you wait?
- **Record decisions.** Every place proto-maker offered a choice (slug? number of alternatives? alt names/angles? winner? iteration changes?), capture what you picked and a one-line *why*.

---

## What to watch at each stage

| Stage | Skill | Watch for |
|---|---|---|
| 1 | `/setup` | Did the interviews pull out things you hadn't written down, or did you just type what you already had? Did any question feel out of place? |
| 2 | `/explore` | Of the seven questions, did any feel redundant or missing? Were the answers easy to short-circuit? |
| 3 | `/refine` | Are the three alternatives meaningfully distinct? Did the critic / user-advocate / engineer memos surface things you hadn't thought of, or restate the obvious? |
| 4 | `/document-scope` | Does the hypothesis force a real commitment, or is "stakeholders like it" the tempting answer? |
| 5 | `/build-prototypes` | Did the parallel designer dispatch produce three different prototypes, or three wireframes with the same skeleton and different labels? In the evolution round, did v2 differ from v1 in substance, not just polish? |
| 6 | `/preview` | Does the local server start first try? Can a non-PM stakeholder use the `?` button without instruction? Did online mode persist annotations to disk where you expected? |
| 7 | `/review-prototypes` | Does the per-alt review structure surface real differences? Could you articulate why the winner won? |
| 8 | `/iterate-prototype` | Did the `.history/iter-1/` snapshot work? Did the rework address the feedback or just restyle? |
| 9 | `/write-user-stories` | Are the stories estimable, or wishlists? Did the engineer's feasibility flag actually flag anything? |
| 10 | `/handoff` | Does `HANDOFF.md` read like a real handoff or like an assembly of boilerplate? Could the engineer estimate without coming back to you? |

---

## Failure modes to watch for

These are LLM-pipeline pathologies we expect could surface:

- **Echo chamber.** The LLM agrees with the PM too much; alternatives are all variations of the PM's first instinct.
- **TBD avalanche.** Every prototype screen has multiple `<mark class="tbd">` callouts and the engineer subagent flags everything as a story. Sign the prototype is too vague.
- **Persona drift.** User-advocate forgets which persona they're channelling, or blurs two.
- **Critic toothlessness.** Never recommends `kill` even when the idea is wobbly. Or only recommends `kill` for nonsense.
- **Designer plagiarism.** alt-2 is alt-1 with renamed nav, alt-3 is alt-1 with rearranged sections.
- **Story–prototype mismatch.** User stories describe behaviour not in the prototype, or omit behaviour visible in the prototype.
- **HANDOFF.md hallucination.** Exec summary contains claims not present in `00-exploration.md` or `02-scope.md`.
- **Frontmatter drift.** A skill's `inputs:` lists files that weren't actually read, or omits ones that were.
- **Refusal-gate failure.** A skill runs without one of its required inputs and produces output anyway. (This should be impossible given AGENTS.md, but it's the kind of thing that breaks under model rotation.)

If you see any of these, capture which stage, which artifact, and a one-line example.

---

## Evaluation rubric

After the run, score each on 1–5 (1 = unacceptable, 3 = OK, 5 = excellent). Total out of 40. This is a delta to compare against future runs, not a pass/fail.

| Dimension | What it measures |
|---|---|
| **Idea fidelity** | Does `HANDOFF.md` describe the idea you actually had? |
| **Alternative distinctiveness** | Were the three alternatives different *angles*, not different shades? |
| **Critique substance** | Did the critic / user-advocate / engineer memos add value or just fill a word count? |
| **Evolution effectiveness** | Did v2 demonstrably improve over v1? |
| **Estimability** | Engineer reports how confident they are estimating from `HANDOFF.md` alone. |
| **Story coherence** | Do user stories cover the prototype without padding? |
| **Stakeholder engagement** | Did real stakeholder annotations capture useful feedback (vs. silence or fluff)? |
| **Time well spent** | Would the PM run this again, voluntarily, on a different idea? |

---

## Output

A single artifact, written by the PM after the run completes:

`docs/dogfood-findings-YYYY-MM-DD.md`

Containing:

1. **Idea** — one sentence.
2. **Roles** — who played PM, stakeholder(s), engineer.
3. **Timing** — total elapsed; per-stage breakdown.
4. **Per-stage observations** — three to five bullets each, drawn from the running log.
5. **Rubric scores** — the eight numbers + total /40.
6. **Failure modes observed** — for each, which stage and a one-line example.
7. **Top fixes** — three to five concrete changes worth making to skills, agents, or the constitution before the next dogfood run. Each fix names a file.
8. **Verdict** — one of:
   - **Ship as-is.** Output is good enough to roll out to a wider audience.
   - **Fix and re-run.** Specific issues block wider rollout; re-run dogfood after fixes.
   - **Back to maintainer queue.** Fundamental issues; not a quick fix.

---

## After the findings

1. For each "Top fix" that's a clear bug, file an entry in TODOS.md (or a new `docs/backlog.md` if the list grows).
2. If verdict is **Fix and re-run**, schedule a focused re-run on the previously-broken stages only. Don't re-run the whole pipeline unless the fixes were structural.
3. If verdict is **Ship as-is**, the v1 ship gate's dogfood items are stronger than the canonical-test pass alone suggests. Capture that explicitly.
4. If verdict is **Back to maintainer queue**, write up what's fundamental in `docs/DECISIONS.md` (a new "decisions reopened" section) — those are the constraints we have to revisit before any further work.

---

## When to run this

- **Once before the first wider rollout** of proto-maker beyond the maintainer.
- **Once after a model upgrade** — the LLM behind every subagent changing is a perturbation that contracts can't catch.
- **Once after any change to AGENTS.md, agent files, or skill bodies** that's bigger than a typo. The constitution is load-bearing.

This is not a CI-cadence test. It's a deliberate quality activity that takes a few hours of PM time plus stakeholder and engineer time. Run it when the cost of a bad handoff is concrete.
