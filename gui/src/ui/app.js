/**
 * Corplex Main UI Coordinator & Cordis Live-Sync Runtime
 */

import { CordisContext } from '../core/context.js';
import { RecurrenceSolver } from '../core/recurrence_solver.js';
import { AmortizedEngine } from '../core/amortized_engine.js';
import { StaticAnalyzer } from '../core/static_analyzer.js';
import { DynamicProfiler } from '../core/dynamic_profiler.js';
import { SpatiotemporalAnalyzer } from '../core/spatiotemporal.js';
import { ALGORITHM_PRESETS } from '../data/presets.js';
import { ChartRenderer } from './charts.js';
import { ASTVisualizer } from './ast_view.js';

export class CorplexApp {
  constructor() {
    this.context = new CordisContext();
    this.currentPresetKey = 'mergesort';
    this.setupEventListeners();
    this.setupLiveSync();
    this.loadPreset('mergesort');
  }

  setupEventListeners() {
    // Tab switching
    document.querySelectorAll('.nav-tab').forEach(tab => {
      tab.addEventListener('click', () => {
        document.querySelectorAll('.nav-tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
        tab.classList.add('active');
        const target = tab.getAttribute('data-tab');
        const pane = document.getElementById(target);
        if (pane) pane.classList.add('active');

        // Trigger chart redraws
        this.updateCharts();
      });
    });

    // Preset selector
    const presetSelect = document.getElementById('preset-select');
    if (presetSelect) {
      presetSelect.addEventListener('change', (e) => {
        this.loadPreset(e.target.value);
      });
    }

    // Master Theorem Inputs
    ['input-a', 'input-b', 'input-c', 'input-k'].forEach(id => {
      const el = document.getElementById(id);
      if (el) {
        el.addEventListener('input', () => this.runMasterTheoremAnalysis());
      }
    });

    // Code Editor Change
    const codeEditor = document.getElementById('code-editor');
    if (codeEditor) {
      codeEditor.addEventListener('input', () => this.runStaticAnalysis());
    }

    // Amortized Slider
    const amortSlider = document.getElementById('amortized-ops-slider');
    if (amortSlider) {
      amortSlider.addEventListener('input', (e) => {
        document.getElementById('amortized-ops-val').textContent = e.target.value;
        this.runAmortizedAnalysis(parseInt(e.target.value));
      });
    }

    // Benchmark Run Button
    const btnBenchmark = document.getElementById('btn-run-benchmark');
    if (btnBenchmark) {
      btnBenchmark.addEventListener('click', () => this.runBenchmark());
    }

    window.addEventListener('resize', () => this.updateCharts());
  }

  setupLiveSync() {
    try {
      const evtSource = new EventSource('/_cordis_live');
      evtSource.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.type === 'hot_reload') {
          console.log('[CORDIS LIVE SYNC] Hot reloading from server change:', data.file);
          window.location.reload();
        }
      };
    } catch (err) {
      console.warn('Cordis Live Sync SSE not active:', err);
    }
  }

  loadPreset(presetKey) {
    this.currentPresetKey = presetKey;
    const preset = ALGORITHM_PRESETS[presetKey];
    if (!preset) return;

    // Update Recurrence form
    if (preset.recurrence) {
      document.getElementById('input-a').value = preset.recurrence.a;
      document.getElementById('input-b').value = preset.recurrence.b;
      document.getElementById('input-c').value = preset.recurrence.c;
      document.getElementById('input-k').value = preset.recurrence.k || 0;
    }

    // Update Code Editor
    const codeEditor = document.getElementById('code-editor');
    if (codeEditor) {
      codeEditor.value = preset.oxcamlCode;
    }

    // Update Summary
    document.getElementById('metric-algo-name').textContent = preset.name;
    document.getElementById('metric-time-bound').textContent = preset.theoreticalTime;
    document.getElementById('metric-space-bound').textContent = preset.theoreticalSpace;

    this.runMasterTheoremAnalysis();
    this.runStaticAnalysis();
    this.runAmortizedAnalysis(32);
    this.updateCharts();
  }

  runMasterTheoremAnalysis() {
    const a = parseFloat(document.getElementById('input-a').value) || 1;
    const b = parseFloat(document.getElementById('input-b').value) || 2;
    const c = parseFloat(document.getElementById('input-c').value) || 0;
    const k = parseFloat(document.getElementById('input-k').value) || 0;

    try {
      const res = RecurrenceSolver.solveMaster(a, b, c, k);
      document.getElementById('master-result-asymp').textContent = res.theta;
      document.getElementById('master-result-case').textContent = res.caseTitle;

      const stepsContainer = document.getElementById('master-steps-list');
      if (stepsContainer) {
        stepsContainer.innerHTML = res.steps.map(s => `<div class="step-item">${s}</div>`).join('');
      }

      this.context.set('current_asymptotic', res.asymptotic);
      ChartRenderer.drawBigOComparison('chart-big-o', res.asymptotic);
    } catch (e) {
      document.getElementById('master-result-asymp').textContent = 'Error: ' + e.message;
    }
  }

  runStaticAnalysis() {
    const code = document.getElementById('code-editor').value;
    const analysis = StaticAnalyzer.analyzeCode(code);

    document.getElementById('stat-cyclomatic').textContent = analysis.cyclomaticComplexity;
    document.getElementById('stat-depth').textContent = analysis.maxLoopDepth;
    document.getElementById('stat-branches').textContent = analysis.branchCount;
    document.getElementById('stat-volume').textContent = analysis.halsteadVolume;
    document.getElementById('stat-inferred-time').textContent = analysis.inferredTime;
    document.getElementById('stat-inferred-space').textContent = analysis.inferredSpace;

    ASTVisualizer.renderCFG('cfg-container', analysis);

    const st = SpatiotemporalAnalyzer.evaluate(analysis.inferredTime, analysis.inferredSpace);
    document.getElementById('st-tradeoff').textContent = st.tradeoff;
    document.getElementById('st-recommendation').textContent = st.recommendation;
    document.getElementById('st-pareto-badge').textContent = st.isPareto ? 'PARETO-OPTIMAL' : 'SUB-OPTIMAL';
    document.getElementById('st-pareto-badge').style.color = st.isPareto ? '#00ffaa' : '#ffb86c';
  }

  runAmortizedAnalysis(opsCount = 32) {
    const isRing = this.currentPresetKey === 'cordis_ring_buffer';
    const amortData = isRing ? AmortizedEngine.simulateCordisRingBuffer(opsCount) : AmortizedEngine.simulateDynamicArray(opsCount);

    document.getElementById('amort-total-actual').textContent = amortData.totalActual;
    document.getElementById('amort-total-amortized').textContent = amortData.totalAmortized;
    document.getElementById('amort-final-phi').textContent = amortData.finalPotential;
    document.getElementById('amort-invariant-badge').textContent = amortData.invariantHolds ? 'INVARIANT HOLDS (Σ a_i ≥ Σ c_i)' : 'VIOLATION';
    document.getElementById('amort-invariant-badge').style.color = amortData.invariantHolds ? '#00ffaa' : '#ff5555';

    ChartRenderer.drawAmortizedSimulation('chart-amortized', amortData);

    const tableBody = document.getElementById('amortized-table-body');
    if (tableBody) {
      tableBody.innerHTML = amortData.history.slice(0, 20).map(h => `
        <tr>
          <td>${h.step}</td>
          <td>${h.opName}</td>
          <td>${h.size} / ${h.capacity}</td>
          <td style="color: ${h.actualCost > 3 ? '#ff5555' : '#00e5ff'}">${h.actualCost}</td>
          <td>${h.phiCurr}</td>
          <td>${h.deltaPhi >= 0 ? '+' : ''}${h.deltaPhi}</td>
          <td style="color: #00ffaa; font-weight: bold;">${h.amortizedCost}</td>
        </tr>
      `).join('');
    }
  }

  runBenchmark() {
    const preset = ALGORITHM_PRESETS[this.currentPresetKey];
    if (!preset || !preset.benchmarkDriver) return;

    const btn = document.getElementById('btn-run-benchmark');
    btn.textContent = 'Profiling...';
    btn.disabled = true;

    setTimeout(() => {
      const { points, fit } = DynamicProfiler.runBenchmark(preset.benchmarkDriver);
      ChartRenderer.drawEmpiricalRegression('chart-empirical', points, fit.bestFit);

      document.getElementById('bench-best-fit').textContent = fit.bestFit.model;
      document.getElementById('bench-r2').textContent = fit.bestFit.r2.toFixed(4);
      document.getElementById('bench-rmse').textContent = fit.bestFit.rmse.toFixed(2);

      btn.textContent = '▶ Run Micro-Benchmark';
      btn.disabled = false;
    }, 50);
  }

  updateCharts() {
    const asymp = this.context.get('current_asymptotic', 'O(n log n)');
    ChartRenderer.drawBigOComparison('chart-big-o', asymp);
    this.runAmortizedAnalysis(parseInt(document.getElementById('amortized-ops-slider')?.value || 32));
  }
}

window.addEventListener('DOMContentLoaded', () => {
  window.corplexApp = new CorplexApp();
});
