# Corplex: Cordis-Style Spatiotemporal Complexity Analysis Kernel in OxCaml

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![OCaml 5+](https://img.shields.io/badge/OCaml-5.0%2B-orange.svg)](https://ocaml.org)
[![OxCaml Ready](https://img.shields.io/badge/OxCaml-Modal%20Unboxed-green.svg)](https://github.com/janestreet)
[![Formal Verification: Rzk](https://img.shields.io/badge/Rzk-Formalized-purple.svg)](https://rzk-lang.github.io)

**Corplex** is a formal, high-performance static and dynamic complexity analysis engine written entirely in native **OxCaml** (OCaml 5+ with Jane Street modal types and algebraic effects), mechanized in **Rzk** simplicial homotopy type theory, and built on the **Cordis-OxCaml** meta-framework.

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
|    STATIC AST & CFG ANALYZER   <=====>   EMPIRICAL PROFILER ENGINE   <=====>   NATIVE CLI HARNESS |
|    - Cyclomatic Complexity (M)           - Multi-Sample Benchmarking           - Interactive CLI  |
|    - Halstead Volume & Depth             - Non-linear O-class Regression       - Step Derivations |
|    - Recurrence Equation Extraction      - R^2 & AIC Model Ranking             - Invariant Checks |
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
   - Simulations for Dynamic Array doubling and Cordis Ring Buffers.

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

---

## 🚀 Quick Start

### 1. Build and Run with Dune
```bash
# Build the native library and executable
dune build @all

# Run the native CLI
dune exec bin/main.exe

# Run the test suite
dune runtest
```

---

## 📜 License & Attributions

Released under the **MIT License** with attributions to:
* **Cordis-OxCaml Meta-Framework**: [cordiverse/cordis](https://github.com/cordiverse/cordis) (DeepSeek-AI / Shigma)
* **OxCaml**: [Jane Street](https://github.com/janestreet)
* **Rzk**: [Rzk Proof Assistant](https://github.com/rzk-lang/rzk)

See [`NOTICE`](./NOTICE) and [`LICENSE`](./LICENSE) for full details.
