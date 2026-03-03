---
name: role-algorithms:numerical-methods
description: Implements numerical methods — floating-point arithmetic (IEEE 754, Kahan summation, catastrophic cancellation), matrix operations (LU/QR/SVD decomposition, sparse formats), root finding (Newton-Raphson, Brent's method), numerical integration (Simpson, Gaussian quadrature, adaptive), FFT/NTT, and cryptographic foundations (SHA-256, AES-GCM, safe implementation patterns). Use when implementing numerical computation, signal processing, matrix algebra, or cryptographic primitives.
allowed-tools: Read, Grep, Glob, Bash
---

# Numerical Methods

## When to use
- Diagnosing floating-point precision issues (cancellation, accumulation error, overflow)
- Choosing between LU, QR, or SVD decomposition for a linear algebra problem
- Implementing root-finding when an analytical solution does not exist
- Selecting a numerical integration method based on smoothness and accuracy requirements
- Using FFT for polynomial multiplication, convolution, or signal analysis
- Reviewing cryptographic primitive usage for correctness and safety

## Core principles
1. **Never compare floats with ==** — always use absolute or relative epsilon; this is not optional
2. **Partial pivoting is not optional in Gaussian elimination** — skipping it breaks numerical stability
3. **SVD is the Swiss Army knife** — when LU and QR fail or when rank matters, SVD solves it
4. **Brent's method is the default root finder** — combines guaranteed convergence with superlinear speed
5. **Never implement your own crypto** — use libsodium, OpenSSL, or Web Crypto API; rolling your own is a security incident waiting to happen

## Reference Files
- `references/floating-point-and-matrix.md` — IEEE 754 pitfalls, Kahan summation, precision type selection, Gaussian elimination with pivoting, LU/QR/SVD decompositions, sparse matrix formats (COO/CSR/CSC)
- `references/root-finding-and-integration.md` — bisection, Newton-Raphson, secant, Brent's method, trapezoidal/Simpson's/Gaussian quadrature, adaptive integration, Cooley-Tukey FFT, NTT for exact polynomial multiplication
- `references/cryptographic-foundations.md` — secure hash functions (SHA-256, BLAKE3), HMAC, AES-256-GCM, ChaCha20-Poly1305, key derivation (Argon2, bcrypt), RSA/ECDSA/ECDH, timing-safe comparisons, CSPRNG usage
