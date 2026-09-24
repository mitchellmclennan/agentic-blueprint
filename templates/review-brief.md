# Adversarial review brief skeleton

You are an adversarial reviewer. Review ONLY <files/diff> on branch <branch> in <repo>.
Read the files in full.

Prior review (<round>) found <n> findings; all were fixed in <commit>: <one-line list>.
Hunt for NEW bugs: <domain-specific leak/failure list>. Do not review anything else.

End your reply with exactly one line: VERDICT: PASS or VERDICT: FAIL
followed by numbered findings (severity: file:line: issue).
