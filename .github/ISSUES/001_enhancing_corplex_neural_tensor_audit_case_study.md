---
title: "RFC: Expanding Corplex with Neural Tensor Invariant Checking, Bitwise Quantization Auditing, and Cache-Thrash Diagnostics (Case Study: Llamaml vs Llama.cpp)"
labels: ["rfc", "enhancement", "tensor-invariants", "quantization", "magic-trace", "corplex-v2"]
assignees: []
---

# RFC: Expanding Corplex for Deep Neural Systems & Invariant Verification

## 1. Executive Summary & Context

**Corplex** is Cordis-OxCaml's static AST complexity analyzer, dynamic benchmark profiler, and Jane Street Magic-Trace hardware tracing kernel. It formalizes space/time complexity bounds via Simplicial Homotopy Type Theory (Rzk) and Cubical Agda.

In our real-world case study analyzing why **`llama.cpp`** successfully executes `Puro-2B-Base.Q4_K_M.gguf` while **`llamaml`** produced corrupted Unicode tokens (`···rãººæŃ»äº¡neså¯¾å¸ĪĠGutenbergáº£i...`), Corplex proved invaluable for analyzing spatiotemporal invariants. However, the investigation highlighted opportunities to evolve Corplex from a general-purpose complexity analyzer into an industry-grade **Formal Neural Kernel & Low-Level Systems Verification Engine**.

---

## 2. Case Study Lessons & Root-Cause Diagnosis

During the `llamaml` audit, five critical failure classes were identified across the inference stack:

| Failure Dimension | `llamaml` Issue Identified | Why Standard Profilers Miss It | How Corplex Can Detect It |
| :--- | :--- | :--- | :--- |
| **1. Quantization Superblock Corruption** | `quant.ml:138-158` scrambled scale packing (`j*2` vs `j+4`) and nibble strides in `Q4_K` dequantization. | The code compiles, runs fast, and has $O(1)$ space, but computes mathematically corrupted floating-point values. | **`Corplex_quant_audit`**: Automated bitfield layout verification comparing OCaml bitwise routines against formal C/GGUF memory specs. |
| **2. Homotopy Coordinate Phase Shift** | `ops.ml:284` applied LLaMA-style adjacent-pair RoPE rotation (`mode = 0`) to a Qwen2 split-half model (`mode = 1`). | Loop depth and branch counts are identical; the bug is purely geometric (orthogonal group $SO(2)$ subspace mismatch). | **`Corplex_homotopy`**: Verification of invariant preservation $\langle \mathbf{R}q, \mathbf{R}k \rangle = f(q, k, \Delta t)$ over synthetic tensor inputs. |
| **3. Inner-Loop Cache Thrashing** | `ops.ml:368` & `quant.ml:402` dequantized blocks repeatedly into shared `static_temp_w` ($O(M N K)$ dequantizations). | Cyclomatic complexity is low ($M = 4$), but cache line thrashing degrades effective throughput by $10\times$. | **`Corplex_cache_trace`**: Magic-Trace hardware counter integration detecting L1/L2 cache misses in tight inner loops. |
| **4. Tokenizer Bijection Failure** | `tokenizer.ml:144` lacked Byte-Level BPE UTF-8 table inverse mappings, emitting raw unicode prefix bytes (e.g. `Ġ`). | String length checks pass, but the round-trip homomorphism $\mathcal{D} \circ \mathcal{E} \simeq \text{id}_{\Sigma^*}$ is broken. | **`Corplex_codec_audit`**: Automated property-based fuzzing testing codec round-trip isomorphism. |

---

## 3. Concrete Architectural Proposals for Corplex V2

### Proposal 1: Dynamic Tensor & Numerical Invariant Checker (`Corplex.Tensor_invariants`)
Introduce runtime and test-time assertions for high-dimensional tensor kernels:
```ocaml
module Tensor_invariants = struct
  (* Verify Quantization Error Bound: |x - dequant(quant(x))| <= delta / 2 *)
  val verify_quant_bound : 
    original:f32_tensor -> quant:u8_tensor -> qtype:quant_type -> max_rel_err:float -> bool

  (* Verify Orthogonal Rotation Invariance under RoPE *)
  val verify_rope_orthogonality : 
    q_rot:f32_tensor -> k_rot:f32_tensor -> head_dim:int -> tolerance:float -> bool

  (* Verify Distribution Invariants (Softmax sums to 1.0, non-negative, no NaNs) *)
  val verify_distribution_invariants : f32_tensor -> (bool, string) result
end
```

### Proposal 2: Bitwise Memory Struct & Nibble Layout Validator (`Corplex.Quant_audit`)
Build a dedicated static validator for SIMD and quantized super-blocks (`Q4_0`, `Q4_K`, `Q5_K`, `Q6_K`, `Q8_0`):
- Automatically generates reference bit vectors and checks that the OCaml dequantizer output exactly matches the canonical C/GGML specification bit-for-bit.
- Detects endianness bugs, nibble ordering discrepancies (low vs high nibble), and scale bitfield shift errors at compile time.

### Proposal 3: Magic-Trace Inner-Loop Cache & Memory Thrash Monitor (`Corplex.Magic_trace`)
Extend Corplex's zero-GC ring buffer tracer to detect:
1. **Redundant Transformations**: Flag functions where the same memory region is dequantized/transformed repeatedly within a nested loop instead of being cached.
2. **L1/L2 Cache Spill Alarms**: Compute working set size $W = \sum \text{buffer\_bytes}$ per loop iteration and emit warnings when $W > 32\text{ KB}$ (standard L1 data cache size).
3. **Global Mutable Buffer Race Warnings**: Detect unsynchronized writes to shared static buffers (such as `static_temp_w`) in multi-threaded execution paths.

### Proposal 4: Automated Cubical Agda / Rzk Proof Stub Generation (`Corplex.Proof_gen`)
Extend `Corplex/lib/static_analyzer.ml` to automatically emit theorem stubs for newly defined OxCaml records and effect handlers:
- Given an OxCaml signature with revertible methods, generate the corresponding `RevertibleEffect` record and `thm-cancel` path equality in Cubical Agda (`formal/agda/`).
- Generate 2-simplex commutativity theorems in Rzk (`formal/rzk/`) for DAG node fusion and state transitions.

### Proposal 5: Codec & Tokenizer Bijective Fuzzing Engine (`Corplex.Codec_fuzz`)
Add an automated property-based test harness that verifies:
$$\forall s \in \Sigma^*, \quad \text{decode}(\text{encode}(s)) \equiv s$$
Validates multi-byte UTF-8 sequences, whitespace prefixes (SentencePiece ` ` vs Byte-BPE `Ġ`), and byte-fallback tokens (`<0xXX>`).

---

## 4. Verification & Formal Invariant Mapping

These features will directly connect Corplex to the formal foundations proved in:
- `Corplex/formal/agda/AmortizedPotential.agda`: Proving upper bounds on amortized potential $\Phi(D)$.
- `llamaml/formal/agda/LlamamlTensor.agda`: Mechanized quantization error bounds.
- `Corplex/rzk/trace_causality.rzk`: Monotonic causality and span nesting in Magic-Trace.

---

*Submitted by Antigravity Agent as part of the Cordis-OxCaml Inference Systems Audit.*
