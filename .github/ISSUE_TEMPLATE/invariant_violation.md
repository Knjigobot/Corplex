---
name: Invariant Violation Report
about: Report a formal invariant or spatiotemporal complexity violation
title: "[INVARIANT VIOLATION] "
labels: ["invariant-violation", "formal-verification"]
assignees: ''
---

### 1. Invariant Description
Describe the formal invariant that was broken (e.g. Quantization error bound, Orthogonal RoPE rotation, LIFO effect rollback, Telescoping sum potential).

### 2. Formal Proof Reference
- **Cubical Agda Module**: (e.g. `Corplex/formal/agda/AmortizedPotential.agda`, `llamaml/formal/agda/LlamamlTensor.agda`)
- **Rzk Simplicial Specification**: (e.g. `Corplex/rzk/trace_causality.rzk`)

### 3. Empirical Evidence & Failure Symptoms
Provide stack traces, benchmark deviations, or corrupted output logs.

### 4. Corplex Static/Dynamic Diagnostics
- Cyclomatic Complexity $M$:
- Memory Allocation Bound:
- Magic-Trace Span Latency:

### 5. Proposed Remediation
Suggested mathematical or algorithmic correction.
