# Corplex: Cordis-Style Spatiotemporal Complexity & Invariant Analysis Kernel in OxCaml

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![OCaml 5+](https://img.shields.io/badge/OCaml-5.0%2B-orange.svg)](https://ocaml.org)
[![OxCaml Ready](https://img.shields.io/badge/OxCaml-Modal%20Unboxed-green.svg)](https://github.com/janestreet)
[![Tracing: Magic-Trace](https://img.shields.io/badge/Tracing-Jane%20Street%20Magic--Trace-blueviolet.svg)](https://github.com/janestreet/magic-trace)
[![Formal Verification: Cubical Agda & Rzk](https://img.shields.io/badge/Formalization-Cubical%20Agda%20%2B%20Rzk-purple.svg)](https://rzk-lang.github.io)

**Corplex** is a formal, high-performance static and dynamic complexity analysis and neural invariant verification engine written entirely in native **OxCaml** (OCaml 5+ with Jane Street modal types, unboxed layouts, and algebraic effects), mechanized in **Cubical Agda** and **Rzk** simplicial homotopy type theory, and powered by **Jane Street Magic-Trace** inspired hardware tracing.

---

## 🏛 Architecture & Component Overview

```
+---------------------------------------------------------------------------------------------------+
|                                            CORPLEX V2                                             |
+---------------------------------------------------------------------------------------------------+
|    RZK & CUBICAL AGDA   |    SPATIAL COMPOSABILITY    |    TEMPORAL COMPOSABILITY   |  OXCAML OPT |
|    - SO(2) Orthogonality|    - Memory Bounds S(n)     |    - Step Counting Effects  |  - Unboxed  |
|    - Quant Contraction  |    - Radix Coeffect Manifold|    - Revertible Simulations |  - GADTs    |
|    - Codec Equivalence  |    - Dynamic Context GADTs  |    - Sliding Sample Buffers |  - Zero-GC  |
|    - Trace Causality (2)|    - Working Set Mon (32KB) |    - Recurrence Solvers     |  - Result/Or|
+-------------------------+-----------------------------+-----------------------------+-------------+
|  STATIC AST/CFG PARSER  <===>  NEURAL TENSOR INVARIANTS  <===>  QUANT AUDIT  <===>  MAGIC-TRACE   |
|  - Cyclomatic M = E-N+2P       - RoPE Invariance (SO2)          - Bitwise Q4_K/Q4_0 - Zero-GC Ring|
|  - Halstead Volume             - Softmax & Norm Bounds          - Scale Layout Val  - Perfetto Exp|
|  - Asymptotic Extraction       - Quant Error Validation         - F16 Decoder Audit - Spill Alarms|
+---------------------------------------------------------------------------------------------------+
```

---

## ⚡ Key Features

1. **Neural Tensor & Numerical Invariant Checker (`Corplex.TensorInvariants`)**:
   - **RoPE SO(2) Orthogonal Invariance**: Verifies $\langle \mathbf{R}_m q, \mathbf{R}_n k \rangle = f(q, k, m-n)$ for both **LLaMA adjacent-pair mode** ($m=0$) and **Qwen2/Puro split-half mode** ($m=1$).
   - **Quantization Error Bound**: Computes absolute, mean squared, and relative error bounds ($|x - \hat{x}| \le \text{tol}$).
   - **Softmax Distribution Sanity**: Checks unit sum ($\sum p_i = 1.0 \pm 10^{-5}$), non-negativity, absence of NaNs/Infs, and finite Shannon entropy $H(p)$.
   - **RMSNorm Scaling**: Validates output RMS normalization $\text{RMS}(y) \approx 1.0 \pm \epsilon$.

2. **Bitwise Quantization Superblock Layout Validator (`Corplex.QuantAudit`)**:
   - Bitfield memory layout validator for low-precision tensor formats (`Q4_0`, `Q4_K`, `Q5_K`, `Q6_K`, `Q8_0`).
   - Automated detection of scale packing stride bugs (e.g. `j*2` vs `j+4`), high/low nibble swaps, and IEEE 754 half-precision float (`f16`) decode correctness.

3. **Jane Street Magic-Trace Cache-Thrash Monitor (`Corplex.CacheTrace` & `Corplex.MagicTrace`)**:
   - **L1/L2 Cache Working Set Monitor**: Tracks per-loop working set size $W = \sum \text{buffer\_bytes}$ and alarms when $W > 32\text{ KB}$ (L1 cache spill threshold).
   - **Redundant Transformation Detector**: Flags inner loops where the same memory address is repeatedly dequantized or converted instead of cached.
   - **Perfetto / Fuchsia Trace Format Export**: Emits standard JSON trace bundles viewable in [ui.perfetto.dev](https://ui.perfetto.dev).

4. **Codec & Tokenizer Bijective Fuzzing Engine (`Corplex.CodecFuzz`)**:
   - Property-based round-trip isomorphism verification: $\forall s \in \Sigma^*, \; \text{decode}(\text{encode}(s)) \equiv s$.
   - Fuzzes multi-byte UTF-8, astral plane code points, Byte-BPE whitespace prefixes (`Ġ`, ` `), and byte-fallback tokens (`<0xXX>`).

5. **Recurrence & Amortized Complexity Solvers**:
   - Master Theorem ($T(n) = a T(n/b) + f(n)$) across all 3 cases and Akra-Bazzi numerical integral root solver.
   - Physicist's Potential Method ($\Phi$) validating $\sum a_i \ge \sum c_i$.

6. **Formal Verification in Cubical Agda & Rzk**:
   - **`formal/agda/TensorInvariants.agda`**: Cubical Agda proofs of $SO(2)$ norm preservation and codec equivalence.
   - **`rzk/quant_homotopy.rzk`**: Simplicial homotopy formalization of quantization projection intervals and contraction bounds on directed interval $\Delta^1 = 2$.
   - **`rzk/trace_causality.rzk`**: Monotonic clock ordering and 2-simplex hierarchical span nesting.

---

## 🚀 Quick Start

### Build and Run with Dune
```bash
# Build the native library and executable
dune build @all

# Run the native CLI with Magic-Trace and Tensor Invariant diagnostics
dune exec bin/main.exe

# Run the full 11-suite test harness
dune runtest
```

---

## 📜 License & Attributions

Released under the **MIT License** with attributions to:
* **Jane Street Magic-Trace**: [janestreet/magic-trace](https://github.com/janestreet/magic-trace) (Jane Street Group LLC)
* **Cordis-OxCaml Meta-Framework**: [cordiverse/cordis](https://github.com/cordiverse/cordis) (DeepSeek-AI / Shigma)
* **OxCaml**: [Jane Street](https://github.com/janestreet)
* **Rzk**: [Rzk Proof Assistant](https://github.com/rzk-lang/rzk)
* **Cubical Agda**: [Agda Community](https://github.com/agda/cubical)

See [`NOTICE`](./NOTICE) and [`LICENSE`](./LICENSE) for full details.
