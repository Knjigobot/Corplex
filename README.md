# Corplex: Cordis-Style Spatiotemporal Complexity Analysis Kernel in OxCaml

**Corplex** is a formal, high-performance static and dynamic complexity analysis engine combining:
1. **Cordis Meta-Framework Architecture** (Spatiotemporal Composability, dynamic coeffects, algebraic effects, reversible execution trails, and live-sync zero-refresh runtime).
2. **OxCaml & Jane Street Mindset** (Strict algebraic data types, modal unboxed layouts, zero-allocation design, GADTs, explicit error handling, Master Theorem / Akra-Bazzi recurrence solving, and amortized potential analysis $\Phi$).
3. **Rzk Formal Verification** (Synthetic $\infty$-categories and simplicial homotopy type theory for formalizing computational step paths, amortized potential inequalities, and spatiotemporal cost bounds).
4. **Interactive GUI & Live Execution Platform** (Real-time code analysis, AST/CFG structural parsing, empirical multi-sample regression profiler with $R^2$ confidence, 2D/3D Big-$O$ comparisons, and Cordis SSE live-sync desktop server).

---

## 🏛 Architecture & Component Overview

```
+---------------------------------------------------------------------------------------------------+
|                                             CORPLEX                                               |
+---------------------------------------------------------------------------------------------------+
|    RZK FORMAL PROOFS    |    SPATIAL COMPOSABILITY    |    TEMPORAL COMPOSABILITY   |  OXCAML OPT |
|    - Step Paths (2)     |    - Memory Bounds S(n)     |    - Step Counting Effects  |  - Unboxed  |
|    - Potential Invariant|    - Topological Comm C(n)  |    - Revertible Simulations |  - GADTs    |
|    - Divide-and-Conquer |    - Dynamic Coeffects      |    - Sliding Sample Buffers |  - Zero-GC  |
|    - Pareto Frontiers   |    - Auxiliary vs Resident  |    - Recurrence Solvers     |  - Result/Or|
+-------------------------+-----------------------------+-----------------------------+-------------+
|    STATIC AST & CFG ANALYZER   <=====>   EMPIRICAL PROFILER ENGINE   <=====>   CORDIS DESKTOP GUI |
|    - Cyclomatic Complexity (M)           - Multi-Sample Benchmarking           - Live Code Editor |
|    - Halstead Volume & Depth             - Non-linear O-class Regression       - 3D/2D Big-O Plot |
|    - Recurrence Equation Extraction      - R^2 & AIC Model Ranking             - Amortized Visual |
+---------------------------------------------------------------------------------------------------+
```

---

## ⚡ Key Features

1. **Recurrence Relation Engine**:
   - Master Theorem ($T(n) = a T(n/b) + f(n)$) covering all 3 standard cases and extended polynomial-logarithmic cases.
   - Akra-Bazzi intuition for non-uniform divide-and-conquer recurrences ($T(n) = \sum a_i T(b_i n) + g(n)$).
   - Linear recurrence characteristic equation solver (Fibonacci, generalized orders).
   
2. **Amortized Analysis ($\Phi$ Potential & Accounting)**:
   - Physicist's Potential Method: tracking $\Phi(D_i)$ across sequence operations.
   - Real-time verification of $\sum a_i = \sum c_i + \Phi(D_k) - \Phi(D_0) \ge \sum c_i$.
   - Interactive simulations for Dynamic Array doubling, Splay Tree zig-zig/zig-zag rotations, and Cordis Ring Buffers.

3. **Static AST & CFG Analyzer**:
   - Control Flow Graph construction from OxCaml / Cordis code.
   - Cyclomatic Complexity $M = E - N + 2P$, nesting depth, branch counting, and Halstead complexity metrics.

4. **Empirical Dynamic Profiler & Curve Fitting**:
   - Multi-sample timing and memory allocation benchmark harness.
   - Non-linear least-squares regression across $O(1), O(\log n), O(\sqrt{n}), O(n), O(n \log n), O(n^2), O(n^3), O(2^n)$.
   - Statistical validation via Coefficient of Determination ($R^2$) and residual analysis.

5. **Formal Verification in Rzk (`rzk/`)**:
   - Mechanized proofs in Simplicial Homotopy Type Theory on directed interval shapes $\Delta^1 = 2$.
   - Proves monotonicity of step reduction paths and non-negativity of amortized potential invariants.

6. **Cordis Zero-Refresh Live Desktop Platform (`gui/`)**:
   - Glassmorphism dark-mode UI with live real-time analysis, interactive graphs, and algorithm presets.
   - Zero-dependency Node.js HTTP server with Server-Sent Events (SSE) live sync.

---

## 🚀 Quick Start

### 1. Launch the Desktop Platform
Run the 1-click batch launcher:
```cmd
RUN.bat
```
or launch manually:
```cmd
node Corplex\gui\server.js
```
Then open `http://localhost:8090` in your browser.

### 2. Run Test Suite
```cmd
node Corplex\test\test_runner.js
```

---

## 📜 License & Attributions

Released under the **MIT License** with attributions to:
* **Cordis Meta-Framework**: [cordiverse/cordis](https://github.com/cordiverse/cordis) (DeepSeek-AI / Shigma)
* **OxCaml**: [Jane Street](https://github.com/janestreet)
* **Rzk**: [Rzk Proof Assistant](https://github.com/rzk-lang/rzk)

See [`NOTICE`](./NOTICE) and [`LICENSE`](./LICENSE) for full details.
