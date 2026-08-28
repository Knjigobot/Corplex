/**
 * Corplex Dynamic Profiler & Non-linear Regression Engine
 */

export class DynamicProfiler {
  static runBenchmark(algorithmFn, inputSizes = [100, 500, 1000, 2500, 5000, 10000]) {
    const points = [];

    inputSizes.forEach(n => {
      // Warmup
      algorithmFn(10);

      const start = performance.now();
      const iterations = n < 500 ? 20 : 5;
      for (let i = 0; i < iterations; i++) {
        algorithmFn(n);
      }
      const end = performance.now();
      const avgDurationMs = (end - start) / iterations;
      const timeNs = avgDurationMs * 1e6;

      points.push({ n, timeMs: avgDurationMs, timeNs });
    });

    const fit = this.fitCandidateModels(points);
    return { points, fit };
  }

  static fitCandidateModels(points) {
    const models = [
      { name: 'O(1)', transform: n => 1 },
      { name: 'O(log n)', transform: n => Math.log(Math.max(1, n)) },
      { name: 'O(sqrt(n))', transform: n => Math.sqrt(n) },
      { name: 'O(n)', transform: n => n },
      { name: 'O(n log n)', transform: n => n * Math.log(Math.max(1, n)) },
      { name: 'O(n^2)', transform: n => n * n },
      { name: 'O(n^3)', transform: n => n * n * n }
    ];

    const xs = points.map(p => p.n);
    const ys = points.map(p => p.timeNs);
    const count = xs.length;
    const meanY = ys.reduce((a, b) => a + b, 0) / count;
    const ssTot = ys.reduce((acc, y) => acc + Math.pow(y - meanY, 2), 0);

    const results = [];

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
      const mse = ssRes / count;
      const aic = count * Math.log(Math.max(1e-9, mse)) + 4;

      results.push({
        model: model.name,
        r2: Math.min(1.0, r2),
        rmse: Math.sqrt(mse),
        aic,
        slope,
        intercept
      });
    });

    results.sort((a, b) => b.r2 - a.r2);
    return {
      bestFit: results[0],
      allFits: results
    };
  }
}
