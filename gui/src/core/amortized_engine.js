/**
 * Corplex Amortized Complexity Engine: Potential Method (Φ) & Banker's Accounting
 */

export class AmortizedEngine {
  static simulateDynamicArray(totalOperations = 32) {
    let size = 0;
    let capacity = 1;
    let phiPrev = 0;
    let sumActual = 0;
    let sumAmortized = 0;
    const history = [];

    for (let i = 1; i <= totalOperations; i++) {
      let isResize = false;
      let actualCost = 1;
      const oldCap = capacity;

      if (size === capacity) {
        isResize = true;
        capacity *= 2;
        actualCost = size + 1;
      }
      size++;

      // Potential function: Phi(D) = 2*size - capacity
      const phiCurr = Math.max(0, 2 * size - capacity);
      const deltaPhi = phiCurr - phiPrev;
      const amortizedCost = actualCost + deltaPhi;

      sumActual += actualCost;
      sumAmortized += amortizedCost;
      phiPrev = phiCurr;

      history.push({
        step: i,
        opName: isResize ? `Resize (${oldCap} → ${capacity})` : 'Push',
        size,
        capacity,
        actualCost,
        phiCurr,
        deltaPhi,
        amortizedCost,
        sumActual,
        sumAmortized
      });
    }

    return {
      history,
      totalActual: sumActual,
      totalAmortized: sumAmortized,
      finalPotential: phiPrev,
      invariantHolds: sumAmortized >= sumActual && phiPrev >= 0
    };
  }

  static simulateCordisRingBuffer(totalOperations = 32, capacity = 8) {
    let count = 0;
    let sumActual = 0;
    let sumAmortized = 0;
    const history = [];

    for (let i = 1; i <= totalOperations; i++) {
      count = Math.min(count + 1, capacity);
      const actualCost = 1;
      const deltaPhi = 0;
      const amortizedCost = 1;

      sumActual += actualCost;
      sumAmortized += amortizedCost;

      history.push({
        step: i,
        opName: 'RingBuffer Push',
        size: count,
        capacity,
        actualCost,
        phiCurr: 0,
        deltaPhi: 0,
        amortizedCost,
        sumActual,
        sumAmortized
      });
    }

    return {
      history,
      totalActual: sumActual,
      totalAmortized: sumAmortized,
      finalPotential: 0,
      invariantHolds: true
    };
  }
}
