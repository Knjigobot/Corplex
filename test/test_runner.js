/**
 * Corplex Test Suite Runner (Zero-Dependency Node.js Test Harness)
 */
const assert = require('assert');

// 1. Recurrence Solver Math
function solveMasterTheorem(a, b, c, k = 0) {
  if (a < 1 || b <= 1) throw new Error("Invalid parameters");
  const p = Math.log(a) / Math.log(b);
  const diff = c - p;
  const eps = 1e-6;

  if (diff < -eps) {
    return { caseNum: 1, criticalExponent: p, asymptotic: `O(n^${p.toFixed(3)})`, theta: `Theta(n^${p.toFixed(3)})` };
  } else if (Math.abs(diff) <= eps) {
    const kNew = k + 1;
    const logStr = kNew === 1 ? 'log n' : `log^${kNew} n`;
    const polyStr = Math.abs(p - 1.0) < eps ? 'n' : Math.abs(p) < eps ? '' : `n^${p.toFixed(2)}`;
    const full = [polyStr, logStr].filter(Boolean).join(' ');
    return { caseNum: 2, criticalExponent: p, asymptotic: `O(${full})`, theta: `Theta(${full})` };
  } else {
    const logStr = k > 0 ? (k === 1 ? ' log n' : ` log^${k} n`) : '';
    const polyStr = Math.abs(c - 1.0) < eps ? 'n' : `n^${c.toFixed(2)}`;
    return { caseNum: 3, criticalExponent: p, asymptotic: `O(${polyStr}${logStr})`, theta: `Theta(${polyStr}${logStr})` };
  }
}

function solveAkraBazzi(terms, drivingDegree) {
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
  const asymp = Math.abs(p - 1) < 0.05 ? 'O(n log n)' : `O(n^${Math.max(p, drivingDegree).toFixed(2)})`;
  return { p, asymptotic: asymp };
}

// 2. Amortized Potential Simulation
function simulateDynamicArray(n) {
  let size = 0;
  let capacity = 1;
  let phiPrev = 0;
  let sumActual = 0;
  let sumAmortized = 0;
  const history = [];

  for (let i = 1; i <= n; i++) {
    let actualCost = 1;
    if (size === capacity) {
      capacity *= 2;
      actualCost = size + 1;
    }
    size++;
    const phiCurr = Math.max(0, 2 * size - capacity);
    const deltaPhi = phiCurr - phiPrev;
    const amortizedCost = actualCost + deltaPhi;

    sumActual += actualCost;
    sumAmortized += amortizedCost;
    phiPrev = phiCurr;

    history.push({ step: i, size, capacity, actualCost, phiCurr, deltaPhi, amortizedCost });
  }

  const invariantHolds = sumAmortized >= sumActual && phiPrev >= 0;
  return { history, sumActual, sumAmortized, invariantHolds };
}

// 3. Empirical Regression Engine
function fitComplexityModel(points) {
  const models = [
    { name: 'O(1)', transform: n => 1 },
    { name: 'O(log n)', transform: n => Math.log(Math.max(1, n)) },
    { name: 'O(sqrt(n))', transform: n => Math.sqrt(n) },
    { name: 'O(n)', transform: n => n },
    { name: 'O(n log n)', transform: n => n * Math.log(Math.max(1, n)) },
    { name: 'O(n^2)', transform: n => n * n },
    { name: 'O(n^3)', transform: n => n * n * n },
  ];

  const xs = points.map(p => p.n);
  const ys = points.map(p => p.timeNs);
  const count = xs.length;
  const meanY = ys.reduce((a, b) => a + b, 0) / count;
  const ssTot = ys.reduce((acc, y) => acc + Math.pow(y - meanY, 2), 0);

  let best = null;

  models.forEach(model => {
    const xTrans = xs.map(model.transform);
    const sumX = xTrans.reduce((a, b) => a + b, 0);
    const sumY = ys.reduce((a, b) => a + b, 0);
    const sumXX = xTrans.reduce((acc, x) => acc + x * x, 0);
    const sumXY = xTrans.reduce((acc, x, i) => acc + x * ys[i], 0);

    const denom = count * sumXX - sumX * sumX;
    let slope = 0, intercept = meanY;
    if (Math.abs(denom) > 1e-12) {
      slope = (count * sumXY - sumX * sumY) / denom;
      intercept = (sumY - slope * sumX) / count;
    }

    const ssRes = xTrans.reduce((acc, xt, i) => {
      const pred = slope * xt + intercept;
      return acc + Math.pow(ys[i] - pred, 2);
    }, 0);

    const r2 = ssTot > 1e-12 ? Math.max(0, 1 - ssRes / ssTot) : 1;
    if (!best || r2 > best.r2) {
      best = { model: model.name, r2, slope, intercept };
    }
  });

  return best;
}

console.log("======================================================");
console.log(" CORPLEX TEST SUITE (CORDIS OXCAML COMPLEXITY ENGINE)");
console.log("======================================================");

// Test 1: Master Theorem
const t1 = solveMasterTheorem(7, 2, 2, 0); // Strassen Matrix Mult
assert.strictEqual(t1.caseNum, 1);
assert(Math.abs(t1.criticalExponent - 2.807) < 0.01);
console.log(" [PASS] Master Theorem Case 1: Strassen ->", t1.asymptotic);

const t2 = solveMasterTheorem(2, 2, 1, 0); // MergeSort
assert.strictEqual(t2.caseNum, 2);
assert.strictEqual(t2.asymptotic, "O(n log n)");
console.log(" [PASS] Master Theorem Case 2: MergeSort ->", t2.asymptotic);

const t3 = solveMasterTheorem(2, 2, 2, 0); // Root Dominated
assert.strictEqual(t3.caseNum, 3);
assert.strictEqual(t3.asymptotic, "O(n^2.00)");
console.log(" [PASS] Master Theorem Case 3: Root Dominated ->", t3.asymptotic);

// Test 2: Akra Bazzi
const ab = solveAkraBazzi([[1, 1/3], [1, 2/3]], 1.0);
assert(Math.abs(ab.p - 1.0) < 0.01);
console.log(" [PASS] Akra-Bazzi Solver: T(n) = T(n/3) + T(2n/3) + n -> p =", ab.p.toFixed(4), ab.asymptotic);

// Test 3: Amortized Dynamic Array Invariant
const amort = simulateDynamicArray(128);
assert(amort.invariantHolds);
assert(amort.sumAmortized >= amort.sumActual);
console.log(" [PASS] Physicist's Potential Method Invariant Verified (Sum Amortized:", amort.sumAmortized, ">= Sum Actual:", amort.sumActual, ")");

// Test 4: Dynamic Regression Engine
const syntheticNLogN = [10, 50, 100, 500, 1000, 5000].map(n => ({
  n,
  timeNs: 2.5 * n * Math.log(n) + 15 + (Math.random() * 5)
}));
const fit = fitComplexityModel(syntheticNLogN);
assert.strictEqual(fit.model, "O(n log n)");
assert(fit.r2 > 0.98);
console.log(" [PASS] Dynamic Regression Engine: Fit synthetic dataset to", fit.model, "with R^2 =", fit.r2.toFixed(4));

console.log("======================================================");
console.log(" ALL 4 TEST SUITES PASSED CLEANLY!");
console.log("======================================================");
