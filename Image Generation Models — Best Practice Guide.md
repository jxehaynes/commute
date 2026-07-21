# 

_Compiled from OpenAI's official prompting documentation and current industry sources, 2026_

---

## 1. The Core Shift: Prompts as Briefs, Not Incantations

The single biggest change in how image models are used well in 2026 is treating a prompt as a structured brief — the same brief an art director would give a photographer — rather than a pile of descriptive adjectives.

A reliable prompt generally covers six areas:

1. **Subject** — what is actually in the frame
2. **Style** — photographic, illustrative, editorial, etc.
3. **Lighting** — source, direction, quality, temperature
4. **Composition** — framing, angle, distance
5. **Mood** — the feel the image should create
6. **Technical constraints** — aspect ratio, resolution, camera/lens language

Vague quality words — "beautiful," "stunning," "amazing," "high quality" — are weak signals. They burn prompt space without meaningfully steering output. Specific, concrete vocabulary — "35mm lens," "soft diffused window light," "eye-level framing" — actually changes what the model produces, because these terms map to strong, consistent patterns in training data.

---

## 2. Structure and Instruction Position

- Write prompts in a consistent order: **scene/background → subject → key details → constraints.** Models process prompts more reliably when structure is predictable.
- Instructions placed at the **start** of a prompt are generally weighted more heavily than instructions buried in the middle. If something is a hard requirement, say it early.
- For prompts with several competing concerns (product accuracy, lighting, pose, framing), **don't rely on stating something once.** Restating a critical constraint at multiple points in the same prompt measurably improves adherence, particularly across multi-step or iterative workflows.
- **Longer isn't always better.** Different models respond differently to prompt length and density — some (Seedream, for instance) perform better with short, precise prompts; others (GPT Image family) read closer to natural paragraphs. What's universal is that _dense, overloaded_ prompts trying to do too many jobs at once dilute every individual instruction. Splitting responsibilities across separate generation steps is more reliable than cramming everything into one prompt.

---

## 3. Constraints: What Must Change vs. What Must Stay the Same

This is one of the most consistently repeated pieces of guidance across current documentation, and arguably the most important for any workflow involving multiple outputs or iterations.

**Explicitly separate what should change from what must remain invariant** — and restate the invariants every time you iterate or generate a related image. Drift compounds silently otherwise.

Practical version of this rule:

- State exclusions and invariants directly: _"no watermark," "no extra text," "preserve exact color and hardware," "do not alter branding."_
- For any edit or iteration on an existing image: use the pattern **"change only X, keep everything else the same"** — and repeat the preserve list on every subsequent iteration, not just the first.
- Negative instructions ("do not add detail not present in the reference") are often more effective than positive ones alone ("be accurate"), because they close off a specific failure mode rather than asserting a general standard the model may still interpret loosely.

---

## 4. Reference Images Beat Text for Anything Visual

Across every credible source, one point holds consistently: **if visual precision matters, show the model — don't just describe it.**

- Reference images are the most reliable way to transfer exact color, texture, likeness, or style. Models are generally very strong at retexturing, restyling, or matching visual character from a reference.
- Text is comparatively unreliable for anything spatial or highly specific — exact hues, precise proportions, spatial relationships like "behind" or "to the left of."
- **Spatial language is a known weak point.** Left/right, in-front/behind instructions are frequently misapplied. The more reliable substitute is either a reference image showing the actual spatial layout, or describing position relative to a fixed, visible landmark in the frame rather than using directional language alone.
- When using a reference image for one purpose (e.g., lighting) but not another (e.g., composition), **say so explicitly** — otherwise the model tends to anchor to the reference's full composition, not just the attribute you intended to transfer.

---

## 5. Composition and Camera Language

Being specific about the shot itself consistently produces more reliable results than describing the desired feeling alone:

- **Framing**: close-up, wide, top-down, waist-up, full body
- **Perspective/angle**: eye-level, low-angle, slightly above
- **Lighting/mood**: soft diffuse, golden hour, high-contrast, hard and directional
- **Placement**: explicit layout instructions where relevant — "subject centered, negative space on left," "logo top-right"

Naming a camera or lens type (e.g., "35mm," "Sony a7s," "shot on film") is a reliable shorthand the model interprets consistently, and is generally more effective than describing the desired realism in abstract terms ("looks professional," "high quality photo").

---

## 6. Aspect Ratio and Technical Specification

- Set aspect ratio explicitly before generating, even when a reference image is also provided — the model benefits from having both signals rather than inferring format from the reference alone.
- For production or batch workflows, quality/fidelity settings represent a genuine trade-off against latency and cost. Lower-fidelity settings are often sufficient and meaningfully faster; reserve maximum fidelity for cases where fine detail (small text, intricate branding) actually matters.

---

## 7. Multi-Image and Iterative Workflows

- Most models retain some memory of previously generated images within the same session, which is useful for controlled edits but can work against you if you want genuine independent variation — starting a fresh session/context for unrelated generation tasks avoids unwanted carryover.
- For workflows generating a _set_ of related images (e.g., a product shot from four angles), the two competing goals are **consistency** (same subject, same lighting, same product) and **variation** (different composition, pose, framing). These pull against each other structurally:
    - Consistency is best carried by **locked, restated text descriptions** and/or a **reference image used explicitly for identity/lighting only.**
    - Variation is best carried by **distinct, explicit composition instructions per image** — not by hoping the model naturally diversifies outputs on repeated similar prompts.
    - If a reference image is used to anchor one image to another, state clearly what it's being used for and what should _not_ be copied from it (composition, framing, pose) — otherwise the model tends to replicate the reference's full composition, not just the intended attribute.

---

## 8. Debugging Bad Outputs

When output doesn't match intent, most current guidance converges on the same diagnostic approach:

1. **Ask the model to restate the prompt it used**, where supported — this often reveals where emphasis landed differently than intended.
2. **Check for conflicting instructions** — a common hidden cause of failure. Two instructions that individually make sense (e.g., "blend naturally into the environment" and "reproduce the product exactly") can actively undermine each other when combined in one prompt.
3. **If the first few iterations are far off, start fresh** rather than continuing to patch — accumulated context can anchor the model to an unwanted direction.
4. **If instructions aren't landing, the fix is often structural, not lexical.** Rather than continuing to reword a single overloaded instruction, split responsibilities into separate steps (extract → describe → generate) so each instruction has less competition for the model's attention.

---

## 9. Model-Specific Notes (as of mid-2026)

Prompting is not fully universal — different model families reward different styles:

|Model family|Preferred style|
|---|---|
|GPT Image models (conversational)|Natural paragraph prose; expands short prompts automatically, so be explicit if you have specific requirements|
|Midjourney|Short, high-signal phrases; front-loaded keywords are weighted more heavily; parameter flags for fine control|
|Stable Diffusion / Flux|Structured, weighted keywords; highly controllable via external tools (ControlNet, LoRA) for precision beyond what text alone can achieve|
|Seedream and similar|Short, precise prompts outperform long, ornate ones|

The practical takeaway: know which model you're building for, and don't assume a prompting style that works well on one will transfer directly to another.

---

## 10. Nano Banana Pro & Nano Banana 2 (Gemini 3 / 3.1 Flash Image) — Specific Notes

Since these are the models most likely underlying the generation nodes in a Sota-style workflow, this section is worth knowing in detail.

**What's structurally different about them:** Both are "thinking" models, not pure diffusion. They reason about a scene — composition, physics, spatial relationships — before producing pixels, and internally generate interim "thought images" to refine layout before committing to a final render. This has real prompting implications: they respond better to being briefed like a human collaborator than to being fed disconnected tags.

**The core prompting shift these models reward:** Stop writing tag lists ("dog, park, 4k, realistic"). Write like a creative director briefing a photographer — full sentences, concrete nouns, real intent. A useful mental model: subject → action → setting → style → composition/camera → lighting/color → text (if any) → constraints. Earlier details in the prompt carry more influence than later ones, so lead with what matters most.

**Locking and editing — this is the standout capability:** Nano Banana Pro/2 are exceptionally strong at _conversational, incremental edits_ rather than full re-generation. If an output is 80% right, don't regenerate from scratch — describe the specific change. The documented pattern for edits is:

- **Lock**: name everything that must not move — exact product details, layout, framing, identity
- **Change**: the single thing being altered
- **Amount**: how far to take the change
- **Constraints**: what the edit must not break (e.g., "don't relight or recolor the product beyond the new ambient light; no new reflections or hotspots")

This maps directly onto the consistency-vs-variation tension in multi-shot workflows — rather than fighting the model with a single dense prompt, the lock/change/amount/constraints structure is the documented, intended way to hold a subject constant while deliberately varying one attribute (e.g., environment) at a time.

**Reference images:** Both models support multiple reference images with assigned roles — up to 14 references, maintaining identity across as many as 5 characters and 10 objects in a single workflow. This is directly relevant to a product/animal/environment pipeline: each reference can be given a distinct role rather than relying on one image to carry multiple kinds of information at once.

**Lighting language:** These models respond specifically to directional, technical lighting language — "soft key light from upper left at 45 degrees, subtle rim light from behind right" is treated the way a real gaffer's note would be. Vague lighting language ("good lighting," "nice light") gives the model nothing concrete to act on.

**Known strength — grounding and consistency:** Nano Banana 2 in particular can pull real-time reference information from web search during generation, improving accuracy for real-world subjects. Both models are built for strong subject/character consistency across a workflow when references and locks are used deliberately, rather than left implicit.

**Practical implication for multi-output pipelines:** Given the reasoning step happens before rendering, being explicit and structured pays off more with these models than with pure diffusion models — they will actually reason over conflicting instructions rather than blending them unpredictably, but that also means an ambiguous or contradictory prompt is more likely to produce a confidently wrong interpretation rather than a vague average. Precision in, precision out.

---

## 11. Summary — The Five Things That Matter Most

1. **Structure over adjectives.** A six-part brief beats a paragraph of vibes.
2. **Say what must not change, every time.** Invariants need repeating, not just stating once.
3. **Show, don't just tell, for anything visual.** Reference images beat text for precision.
4. **Split the job, don't overload one instruction.** Structural separation beats prompt refinement when instructions compete.
5. **Debug by checking for conflict, not just by adding more words.** Most failures come from two reasonable instructions pulling against each other, not from insufficient description.
6. **For Nano Banana Pro/2 specifically: edit, don't regenerate.** Use the lock/change/amount/constraints pattern to hold a subject steady while deliberately varying one thing — this is the model's core strength and the most reliable route to consistency across a multi-image set.