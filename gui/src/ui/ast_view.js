/**
 * Corplex AST & Control Flow Graph (CFG) Visualizer
 */

export class ASTVisualizer {
  static renderCFG(containerId, staticData) {
    const container = document.getElementById(containerId);
    if (!container) return;

    const { fnName, isRecursive, cyclomaticComplexity, branchCount, maxLoopDepth, halsteadVolume } = staticData;

    container.innerHTML = `
      <div style="display: flex; flex-direction: column; gap: 10px; font-family: var(--font-mono); font-size: 12px;">
        <div style="background: var(--bg-tertiary); padding: 10px; border-radius: 6px; border: 1px solid var(--border-color);">
          <div style="color: var(--accent-cyan); font-weight: bold; margin-bottom: 6px;">
            FUNCTION: ${fnName} ${isRecursive ? '<span style="color: var(--accent-yellow);">(Recursive)</span>' : ''}
          </div>
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px;">
            <div>Cyclomatic Complexity (M): <strong style="color: var(--accent-green);">${cyclomaticComplexity}</strong></div>
            <div>Max Loop Depth: <strong style="color: var(--accent-cyan);">${maxLoopDepth}</strong></div>
            <div>Branch Predicates: <strong style="color: var(--accent-orange);">${branchCount}</strong></div>
            <div>Halstead Program Volume: <strong style="color: var(--accent-purple);">${halsteadVolume}</strong></div>
          </div>
        </div>

        <div style="background: #0d1117; padding: 12px; border-radius: 6px; border: 1px solid var(--border-color); line-height: 1.6;">
          <div style="color: var(--text-secondary); margin-bottom: 4px;">// Control-Flow Graph Topology</div>
          <div style="color: var(--accent-green);">[ENTRY] ──▶ Node_0 (Init & Params)</div>
          ${isRecursive ? `<div style="color: var(--accent-yellow); padding-left: 15px;">│ ──▶ [BRANCH COND] (Base Case) ──▶ [RETURN BASE]</div>
<div style="color: var(--accent-purple); padding-left: 15px;">│ ──▶ [RECURSIVE CALL] Subproblems T(n/b)</div>` : ''}
          ${maxLoopDepth > 0 ? `<div style="color: var(--accent-cyan); padding-left: 15px;">│ ──▶ [LOOP HEADER] (Depth ${maxLoopDepth}) ──▶ [BODY OP] ──↺</div>` : ''}
          <div style="color: var(--accent-green);">└──▶ [EXIT] (Return Value)</div>
        </div>
      </div>
    `;
  }
}
