/**
 * Corplex Charting Engine: Canvas-based Big-O, Amortized & Empirical Renderers
 */

export class ChartRenderer {
  static drawBigOComparison(canvasId, highlightedClass = 'O(n log n)') {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const width = canvas.width = canvas.parentElement.clientWidth;
    const height = canvas.height = 280;

    ctx.clearRect(0, 0, width, height);

    // Padding & Axes
    const pad = { top: 30, right: 120, bottom: 40, left: 50 };
    const chartW = width - pad.left - pad.right;
    const chartH = height - pad.top - pad.bottom;

    // Grid lines
    ctx.strokeStyle = '#223249';
    ctx.lineWidth = 1;
    for (let i = 0; i <= 5; i++) {
      const y = pad.top + (chartH / 5) * i;
      ctx.beginPath();
      ctx.moveTo(pad.left, y);
      ctx.lineTo(pad.left + chartW, y);
      ctx.stroke();
    }

    // Functions
    const curves = [
      { name: 'O(1)', fn: n => 10, color: '#00ffaa' },
      { name: 'O(log n)', fn: n => Math.log(n) * 15, color: '#00b4d8' },
      { name: 'O(sqrt(n))', fn: n => Math.sqrt(n) * 12, color: '#70d6ff' },
      { name: 'O(n)', fn: n => n * 1.5, color: '#ffd166' },
      { name: 'O(n log n)', fn: n => n * Math.log(n) * 0.4, color: '#ff9f1c' },
      { name: 'O(n^2)', fn: n => Math.pow(n, 2) * 0.02, color: '#ff5555' },
      { name: 'O(2^n)', fn: n => Math.pow(2, n * 0.15), color: '#bd93f9' }
    ];

    const maxN = 100;
    const maxY = 150;

    curves.forEach(c => {
      ctx.beginPath();
      const isSelected = c.name === highlightedClass || highlightedClass.includes(c.name);
      ctx.strokeStyle = c.color;
      ctx.lineWidth = isSelected ? 3.5 : 1.5;
      if (!isSelected) ctx.globalAlpha = 0.4;
      else ctx.globalAlpha = 1.0;

      for (let n = 2; n <= maxN; n += 2) {
        const val = Math.min(maxY, c.fn(n));
        const x = pad.left + (n / maxN) * chartW;
        const y = pad.top + chartH - (val / maxY) * chartH;
        if (n === 2) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();

      // Label at end
      const finalY = pad.top + chartH - (Math.min(maxY, c.fn(maxN)) / maxY) * chartH;
      ctx.fillStyle = c.color;
      ctx.font = isSelected ? 'bold 11px JetBrains Mono' : '10px JetBrains Mono';
      ctx.fillText(c.name, pad.left + chartW + 8, Math.max(pad.top + 10, finalY + 3));
    });

    ctx.globalAlpha = 1.0;

    // Axis Labels
    ctx.fillStyle = '#8b949e';
    ctx.font = '11px JetBrains Mono';
    ctx.fillText('Input Size (n)', pad.left + chartW / 2 - 40, height - 10);
    ctx.save();
    ctx.translate(15, pad.top + chartH / 2 + 30);
    ctx.rotate(-Math.PI / 2);
    ctx.fillText('Operations / Latency', 0, 0);
    ctx.restore();
  }

  static drawAmortizedSimulation(canvasId, amortizedData) {
    const canvas = document.getElementById(canvasId);
    if (!canvas || !amortizedData) return;
    const ctx = canvas.getContext('2d');
    const width = canvas.width = canvas.parentElement.clientWidth;
    const height = canvas.height = 280;

    ctx.clearRect(0, 0, width, height);
    const pad = { top: 30, right: 30, bottom: 40, left: 50 };
    const chartW = width - pad.left - pad.right;
    const chartH = height - pad.top - pad.bottom;

    const history = amortizedData.history;
    const count = history.length;
    if (count === 0) return;

    const maxActual = Math.max(...history.map(h => h.actualCost), 8);
    const maxPhi = Math.max(...history.map(h => h.phiCurr), 8);
    const scaleMax = Math.max(maxActual, maxPhi) * 1.15;

    // Grid lines
    ctx.strokeStyle = '#223249';
    ctx.lineWidth = 1;
    for (let i = 0; i <= 4; i++) {
      const y = pad.top + (chartH / 4) * i;
      ctx.beginPath();
      ctx.moveTo(pad.left, y);
      ctx.lineTo(pad.left + chartW, y);
      ctx.stroke();
      const val = Math.round(scaleMax - (scaleMax / 4) * i);
      ctx.fillStyle = '#586069';
      ctx.font = '10px JetBrains Mono';
      ctx.fillText(val.toString(), pad.left - 30, y + 4);
    }

    const colWidth = (chartW / count) * 0.7;

    // 1. Draw Actual Cost Bars
    history.forEach((h, i) => {
      const x = pad.left + (i / count) * chartW + colWidth * 0.2;
      const barH = (h.actualCost / scaleMax) * chartH;
      const y = pad.top + chartH - barH;

      ctx.fillStyle = h.actualCost > 3 ? '#ff5555' : '#00e5ff';
      ctx.fillRect(x, y, colWidth, barH);
    });

    // 2. Draw Amortized Cost Line (Flat constant)
    ctx.beginPath();
    ctx.strokeStyle = '#00ffaa';
    ctx.lineWidth = 2.5;
    ctx.setLineDash([4, 4]);
    history.forEach((h, i) => {
      const x = pad.left + (i / count) * chartW + colWidth * 0.5;
      const y = pad.top + chartH - (h.amortizedCost / scaleMax) * chartH;
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.stroke();
    ctx.setLineDash([]);

    // 3. Draw Potential Line Phi(D)
    ctx.beginPath();
    ctx.strokeStyle = '#ffd166';
    ctx.lineWidth = 2;
    history.forEach((h, i) => {
      const x = pad.left + (i / count) * chartW + colWidth * 0.5;
      const y = pad.top + chartH - (h.phiCurr / scaleMax) * chartH;
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.stroke();

    // Legend
    ctx.fillStyle = '#ff5555';
    ctx.fillRect(pad.left, 12, 10, 10);
    ctx.fillStyle = '#e6edf3';
    ctx.font = '11px JetBrains Mono';
    ctx.fillText('Actual Cost c_i', pad.left + 16, 21);

    ctx.fillStyle = '#00ffaa';
    ctx.fillRect(pad.left + 140, 12, 10, 10);
    ctx.fillText('Amortized a_i (O(1))', pad.left + 156, 21);

    ctx.fillStyle = '#ffd166';
    ctx.fillRect(pad.left + 300, 12, 10, 10);
    ctx.fillText('Potential Φ(D)', pad.left + 316, 21);
  }

  static drawEmpiricalRegression(canvasId, points, bestFit) {
    const canvas = document.getElementById(canvasId);
    if (!canvas || !points || points.length === 0) return;
    const ctx = canvas.getContext('2d');
    const width = canvas.width = canvas.parentElement.clientWidth;
    const height = canvas.height = 280;

    ctx.clearRect(0, 0, width, height);
    const pad = { top: 30, right: 40, bottom: 40, left: 60 };
    const chartW = width - pad.left - pad.right;
    const chartH = height - pad.top - pad.bottom;

    const maxN = Math.max(...points.map(p => p.n));
    const maxTime = Math.max(...points.map(p => p.timeNs)) * 1.2;

    // Grid
    ctx.strokeStyle = '#223249';
    ctx.lineWidth = 1;
    for (let i = 0; i <= 4; i++) {
      const y = pad.top + (chartH / 4) * i;
      ctx.beginPath();
      ctx.moveTo(pad.left, y);
      ctx.lineTo(pad.left + chartW, y);
      ctx.stroke();
      const val = ((maxTime - (maxTime / 4) * i) / 1e3).toFixed(1) + ' µs';
      ctx.fillStyle = '#586069';
      ctx.font = '10px JetBrains Mono';
      ctx.fillText(val, pad.left - 50, y + 4);
    }

    // Points
    ctx.fillStyle = '#00e5ff';
    points.forEach(p => {
      const x = pad.left + (p.n / maxN) * chartW;
      const y = pad.top + chartH - (p.timeNs / maxTime) * chartH;
      ctx.beginPath();
      ctx.arc(x, y, 5, 0, Math.PI * 2);
      ctx.fill();
    });

    // Fitted Curve
    if (bestFit) {
      ctx.beginPath();
      ctx.strokeStyle = '#00ffaa';
      ctx.lineWidth = 2.5;

      const transform = n => {
        if (bestFit.model === 'O(1)') return 1;
        if (bestFit.model === 'O(log n)') return Math.log(Math.max(1, n));
        if (bestFit.model === 'O(sqrt(n))') return Math.sqrt(n);
        if (bestFit.model === 'O(n)') return n;
        if (bestFit.model === 'O(n log n)') return n * Math.log(Math.max(1, n));
        if (bestFit.model === 'O(n^2)') return n * n;
        if (bestFit.model === 'O(n^3)') return n * n * n;
        return n;
      };

      for (let n = 1; n <= maxN; n += maxN / 100) {
        const pred = bestFit.slope * transform(n) + bestFit.intercept;
        const x = pad.left + (n / maxN) * chartW;
        const y = pad.top + chartH - (pred / maxTime) * chartH;
        if (n === 1) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();
    }

    // Title / Metrics
    ctx.fillStyle = '#e6edf3';
    ctx.font = '12px JetBrains Mono';
    ctx.fillText(`Best Fit: ${bestFit ? bestFit.model : 'N/A'} (R² = ${bestFit ? bestFit.r2.toFixed(4) : '0'})`, pad.left, 18);
  }
}
