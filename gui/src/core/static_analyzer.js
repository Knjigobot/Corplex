/**
 * Corplex Static Code Analyzer: AST, CFG & Complexity Metrics
 */

export class StaticAnalyzer {
  static analyzeCode(sourceCode) {
    const lines = sourceCode.split('\n');
    let cyclomaticComplexity = 1;
    let maxLoopDepth = 0;
    let currentDepth = 0;
    let branchCount = 0;
    let allocationCount = 0;
    let isRecursive = false;

    const fnNameMatch = sourceCode.match(/let\s+(?:rec\s+)?([a-zA-Z0-9_]+)/);
    const fnName = fnNameMatch ? fnNameMatch[1] : 'anonymous';

    if (sourceCode.includes('let rec') || (fnName && new RegExp(`\\b${fnName}\\b`, 'g').test(sourceCode.replace(/let\s+rec\s+\w+/, '')))) {
      isRecursive = true;
    }

    const operators = new Set();
    const operands = new Set();
    let totalOperators = 0;
    let totalOperands = 0;

    const opTokens = ['+', '-', '*', '/', '%', '==', '!=', '<', '<=', '>', '>=', '&&', '||', ':=', '->', '|', ';'];

    lines.forEach(line => {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('(*') || trimmed.startsWith('//')) return;

      // Loop depth tracking
      if (/\b(for|while)\b/.test(trimmed) || trimmed.includes('do')) {
        currentDepth++;
        if (currentDepth > maxLoopDepth) maxLoopDepth = currentDepth;
      }
      if (trimmed.includes('done') || trimmed.endsWith('}')) {
        if (currentDepth > 0) currentDepth--;
      }

      // Branches & Predicates
      const ifMatches = (trimmed.match(/\b(if|match|when|while|for)\b/g) || []).length;
      if (ifMatches > 0) {
        branchCount += ifMatches;
        cyclomaticComplexity += ifMatches;
      }

      // Allocations
      if (/\b(Array\.make|ref|malloc|new|alloc)\b/.test(trimmed)) {
        allocationCount++;
      }

      // Halstead metrics tokenization
      opTokens.forEach(op => {
        const count = (line.split(op).length - 1);
        if (count > 0) {
          operators.add(op);
          totalOperators += count;
        }
      });

      const words = trimmed.match(/[a-zA-Z_][a-zA-Z0-9_]*/g) || [];
      words.forEach(w => {
        if (!opTokens.includes(w)) {
          operands.add(w);
          totalOperands++;
        }
      });
    });

    const n1 = operators.size;
    const n2 = operands.size;
    const N = totalOperators + totalOperands;
    const vocab = n1 + n2;
    const halsteadVolume = vocab > 1 ? N * (Math.log(vocab) / Math.log(2)) : 0;

    let inferredTime = 'O(1)';
    if (isRecursive) {
      inferredTime = maxLoopDepth > 0 ? 'O(n log n)' : 'O(log n)';
    } else if (maxLoopDepth === 1) {
      inferredTime = 'O(n)';
    } else if (maxLoopDepth === 2) {
      inferredTime = 'O(n^2)';
    } else if (maxLoopDepth >= 3) {
      inferredTime = `O(n^${maxLoopDepth})`;
    }

    const inferredSpace = isRecursive ? 'O(log n)' : (allocationCount > 0 ? 'O(n)' : 'O(1)');

    return {
      fnName,
      isRecursive,
      cyclomaticComplexity,
      branchCount,
      maxLoopDepth,
      allocationCount,
      halsteadVolume: Math.round(halsteadVolume),
      inferredTime,
      inferredSpace
    };
  }
}
