# Adversarial review brief skeleton

You are an adversarial reviewer. Review ONLY <files/diff> on branch <branch> in <repo>.
Read the files in full.

Prior review (<round>) found <n> findings; all were fixed in <commit>: <one-line list>.
Hunt for NEW bugs: <domain-specific leak/failure list>. Do not review anything else.

End your reply with exactly one line: VERDICT: PASS or VERDICT: FAIL
followed by numbered findings (severity: file:line: issue).

## Frontend quality rules - all Clanker prompts

Apply these rules to every frontend build, change and review. Backend-only work keeps its scope; these rules do not request an audit, redesign or unrelated UI changes.

Keep each product's approved brand, design tokens, fonts, palette, assets and component system. These are quality checks, not permission to introduce a generic theme, recolour a product or replace its identity. No emoji in product UI. Do not invent product screens, claims, metrics or customer evidence.

1. Delete filler badges that add no useful information.
2. Drop redundant labels when context already explains the content.
3. Remove arbitrary italic emphasis; keep intentional brand typography.
4. Use monospace only where it helps, such as code, identifiers and technical values.
5. Use the product's existing design system and tokens; extend it consistently when necessary.
6. Show the actual product or workflow, not decoration standing in for it.
7. Give the main feature enough size and visual priority.
8. Group related content with spacing and clear hierarchy instead of unnecessary boxes.
9. Make headlines specific to the product, task and user value. Avoid generic AI copy.
10. Make the primary call to action clear and visually distinct without competing CTAs.
11. Use an intentional accent from the approved brand palette. Do not add a new colour scheme.
12. Keep icons consistent in family, size, stroke and meaning. Never substitute emoji.
13. Remove decorative embellishments that do not aid understanding or interaction.
14. For nested rounded surfaces, derive inner radius from outer radius minus padding, clamped at zero; inspect the result visually.
15. Ensure readable text contrast in every supported theme and interaction state.
16. Wrap headlines intentionally at real viewport widths; avoid orphan words, clipping and awkward breaks.
17. Align by eye as well as by measurements; inspect actual rendered pixels.
18. Use tabular numerals for changing values, comparisons and numeric columns where alignment matters.
19. Include clear loading states, plus empty, error and disabled states where the workflow needs them.
20. Animate useful interaction feedback, not decoration. Respect reduced-motion preferences.

Frontend acceptance: inspect the actual rendered result at relevant desktop/mobile widths and supported themes; check hierarchy, spacing, typography, contrast, alignment, wrapping and interaction states. Tests or a successful build do not replace visual inspection. Preserve existing data and unrelated work. Do not claim these rules authorize production deployment.

Prompt delivery: include this entire block in every Clanker lane, builder, reviewer, retry/resume and ad-hoc prompt, directly or through a verified automatically loaded instruction file. For isolated/private-HOME/container runs, explicitly copy or mount the rules and verify they are loaded; do not assume the host's global rules are visible. Apply frontend checks only to frontend scope, not unrelated backend work. Do not rewrite historical prompt logs or evidence.

Source: Mitchell's November 7, 2026 instruction to add the principles from https://www.instagram.com/reel/DfcnAJFhAa1/ to frontend rules and all Clanker prompts. This is standing guidance, not a request for a frontend audit.
