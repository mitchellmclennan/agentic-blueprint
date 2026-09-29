// OpenCode v1 tool hooks. No package installs or network calls.
import { spawnSync } from 'node:child_process'
export const Guardrails = async ({ worktree, directory }) => {
  const cwd = worktree || directory || process.cwd()
  return {
    'tool.execute.before': async (input, output) => {
      const result = spawnSync('python3', ['.agent-guardrails/guard.py', 'tool'], {
        cwd, input: JSON.stringify({ tool: input.tool, args: output.args }), encoding: 'utf8', timeout: 3000
      })
      if (result.status !== 0) throw new Error(result.stderr?.trim() || 'Guardrail unavailable; tool blocked')
    },
    'tool.execute.after': async () => { /* no side effect: tool outcome stays visible */ }
  }
}
