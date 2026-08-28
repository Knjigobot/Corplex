/**
 * Corplex Recurrence Equation Solver: Master Theorem & Akra-Bazzi
 */

export class RecurrenceSolver {
  static solveMaster(a, b, c, k = 0) {
    if (a < 1 || b <= 1) {
      throw new Error('Master Theorem requires a >= 1 and b > 1');
    }

    const p = Math.log(a) / Math.log(b);
    const diff = c - p;
    const eps = 1e-5;
    const steps = [];

    steps.push(`Identified recurrence: T(n) = ${a} T(n/${b}) + Θ(n^${c}${k > 0 ? ` log^${k} n` : ''})`);
    steps.push(`Critical exponent: p = log_b(a) = log_${b}(${a}) = ${p.toFixed(4)}`);
    steps.push(`Driving polynomial degree: c = ${c.toFixed(4)} (Difference c - p = ${diff.toFixed(4)})`);

    if (diff < -eps) {
      // Case 1
      const notation = Math.abs(p - 1) < eps ? 'O(n)' : Math.abs(p - 2) < eps ? 'O(n^2)' : Math.abs(p - 3) < eps ? 'O(n^3)' : `O(n^${p.toFixed(3)})`;
      const theta = notation.replace('O', 'Θ');
      steps.push(`Case 1 applies (c < log_b(a)): Subproblem leaf evaluation dominates total work.`);
      steps.push(`Result: T(n) = ${theta}`);
      return {
        caseNum: 1,
        caseTitle: 'Case 1: Leaf Work Dominates',
        criticalExponent: p,
        asymptotic: notation,
        theta,
        steps
      };
    } else if (Math.abs(diff) <= eps) {
      // Case 2
      const kNew = k + 1;
      const logStr = kNew === 1 ? 'log n' : `log^${kNew} n`;
      const polyStr = Math.abs(p - 1.0) < eps ? 'n' : Math.abs(p) < eps ? '' : `n^${p.toFixed(2)}`;
      const combined = [polyStr, logStr].filter(Boolean).join(' ');
      const notation = `O(${combined})`;
      const theta = `Θ(${combined})`;
      steps.push(`Case 2 applies (c = log_b(a)): Work is evenly distributed across all tree levels.`);
      steps.push(`Result: T(n) = ${theta}`);
      return {
        caseNum: 2,
        caseTitle: 'Case 2: Balanced Tree Levels',
        criticalExponent: p,
        asymptotic: notation,
        theta,
        steps
      };
    } else {
      // Case 3
      const logStr = k > 0 ? (k === 1 ? ' log n' : ` log^${k} n`) : '';
      const polyStr = Math.abs(c - 1.0) < eps ? 'n' : `n^${c.toFixed(2)}`;
      const notation = `O(${polyStr}${logStr})`;
      const theta = `Θ(${polyStr}${logStr})`;
      const regularityFactor = a / Math.pow(b, c);
      steps.push(`Case 3 applies (c > log_b(a)): Root divide/combine work dominates total work.`);
      steps.push(`Regularity condition verified: a*(n/b)^c <= d*n^c for d = ${regularityFactor.toFixed(4)} < 1.`);
      steps.push(`Result: T(n) = ${theta}`);
      return {
        caseNum: 3,
        caseTitle: 'Case 3: Root Work Dominates',
        criticalExponent: p,
        asymptotic: notation,
        theta,
        steps
      };
    }
  }

  static solveAkraBazzi(terms, drivingDegree = 1.0) {
    // Solve sum(a_i * b_i^p) = 1
    function f(p) {
      return terms.reduce((acc, [a, b]) => acc + a * Math.pow(b, p), 0);
    }
    let low = -5, high = 15;
    for (let i = 0; i < 100; i++) {
      const mid = (low + high) / 2;
      const v = f(mid);
      if (Math.abs(v - 1) < 1e-9) { low = mid; break; }
      if (v > 1) low = mid;
      else high = mid;
    }
    const p = (low + high) / 2;
    const steps = [
      `Akra-Bazzi characteristic condition: ∑ a_i * b_i^p = 1 with ${terms.length} subproblem terms`,
      `Numerically solved characteristic exponent: p = ${p.toFixed(4)}`,
      `Driving polynomial degree: g(n) = Θ(n^${drivingDegree.toFixed(2)})`
    ];
    let notation = '';
    if (drivingDegree < p) {
      notation = `O(n^${p.toFixed(3)})`;
    } else if (Math.abs(drivingDegree - p) < 0.01) {
      notation = `O(n^${p.toFixed(2)} log n)`;
    } else {
      notation = `O(n^${drivingDegree.toFixed(2)})`;
    }
    return { p, asymptotic: notation, theta: notation.replace('O', 'Θ'), steps };
  }
}
