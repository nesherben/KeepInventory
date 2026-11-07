---
name: feature
description: Build a new KeepInventory feature with a team of subagents - analyst + product/UX designer in parallel, user approval, implementation by the main agent, then an independent code review whose fixes are applied. Invoke only with /feature.
disable-model-invocation: true
---

# feature — equipo de agentes

Input: the feature request in `$ARGUMENTS` (or the user's last message). Keep the user informed in short lines between phases. All user-facing text in Spanish.

## Fase 1 — Análisis y diseño (en paralelo)
Launch both in ONE message (parallel), each with the full feature request and any decisions already made in the conversation:
- `feature-analyst` → what code to change/add.
- `product-designer` → improvements to the idea + UI/UX design.

Skip `product-designer` if the feature has no UI or the user already specified the design in detail. Don't re-explore what the agents report; trust their `path:line` references and only read ranges you need to implement.

## Fase 2 — Plan y aprobación (checkpoint obligatorio)
Merge both reports into one short plan for the user (≤ 30 lines): cambios por capa, diseño de UI, migración de BD, riesgos.
Then use AskUserQuestion:
- multiSelect question with the designer's suggested improvements (⭐ first, marked "(Recomendado)").
- one question per real "Duda" from the analyst, if any.
Do not write code until the user answers.

## Fase 3 — Implementación (agente principal)
Implement it yourself (you hold the context; do NOT delegate coding). Use `l10n-add` for texts, `code-map` to navigate, add/update tests for pure logic and DB migrations. Run `bash .claude/skills/verify/verify.sh` until clean.

## Fase 4 — Revisión independiente
Launch `code-reviewer` with: the feature goal, the approved plan (incl. chosen improvements) and the list of changed files. Then:
- Apply every `crítico`/`importante` finding you agree with; for ones you disagree with, say why in one line.
- Apply `menor` findings only if cheap.
- Re-run `verify.sh`. Re-launch the reviewer only if critical fixes were large.

## Fase 5 — Resumen
Short summary: what was built, decisions taken, review findings applied/rejected, verify result, anything left to test on the device. Don't commit or bump the version unless the user asks (then use `bump-version`).
