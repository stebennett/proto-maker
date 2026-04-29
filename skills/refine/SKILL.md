---
name: refine
description: Stage 2. Generates 2-4 candidate alternatives for the explored idea, dispatches Critic, User Advocate, and Engineer subagents to attack the alternatives, synthesizes a verdict (proceed/revise/kill). Reads 00-exploration.md. Writes 01-alternatives.md.
---

# $refine — stage 2: alternatives + verdict

## Inputs

- `context/*`
- `ideas/<slug>/00-exploration.md`

## Refuse if

- `context/` empty (run `$setup`)
- `00-exploration.md` missing (run `$explore`)

## Process

1. Read inputs.
2. Identify the idea slug. If the PM is running this directly, ask which idea
   if it's ambiguous.
3. Propose 3 alternatives (default; ask PM if they want 2 or 4 instead). Each
   alternative is one paragraph: a different angle on solving the explored
   problem (e.g., minimalist, guided, power-user, automated).
4. Show the PM the three alternatives. Confirm or adjust.
5. Dispatch THREE subagents IN PARALLEL, each receiving the alternatives summary:
   - `critic` — overall premise + recommendation verdict
   - `user-advocate` — persona-side critique of the alternative space
   - `engineer` — feasibility + constraint-conflict critique
6. Wait for all three. If any returns garbage, retry once per AGENTS.md tension
   protocol.
7. Synthesize into `ideas/<slug>/01-alternatives.md`. The file has two
   sections: a markdown body, then a fenced YAML verdict block at the end.

The markdown body (write verbatim, replacing `<...>` placeholders):

    ---
    stage: 2
    idea: <slug>
    updated: <YYYY-MM-DD>
    inputs: [context/, 00-exploration.md]
    ---

    # Alternatives for <idea title>

    ## Alternative 1: <angle name>
    <paragraph>

    ## Alternative 2: <angle name>
    <paragraph>

    ## Alternative 3: <angle name>
    <paragraph>

    ## Critic memo
    <full critic memo>

    ## User Advocate memo
    <full user-advocate memo>

    ## Engineer memo
    <full engineer memo>

Then, immediately after, append a YAML verdict block as a fenced code block.
The block MUST start at column 0 (no indentation) so `contracts.sh` can match
the `^recommendation:` line:

    ```yaml
    recommendation: proceed | revise | kill
    justification: |
      Two-sentence prose synthesis: which alternatives the verdict applies to,
      and the one-sentence why. Pull this from the critic's recommendation block.
    ```

8. If verdict is `kill`, tell the PM:
   "The critic recommends killing this alternative space. Read the memo and
   decide: (a) revise this idea via `$explore` again, (b) override the verdict
   and continue with `$document-scope`, or (c) abandon."

## Done

Tell PM: "Alternatives written to `01-alternatives.md`. Verdict: <verdict>.
Next step: `$document-scope`."
